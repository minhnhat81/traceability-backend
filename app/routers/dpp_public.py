# app/routers/dpp_public.py
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from typing import Any
import json
from datetime import datetime

from app.core.db import get_db
from .blockchain import _build_and_optionally_upload_dpp

router = APIRouter(prefix="/api/public", tags=["dpp-public"])


# ----------------------------
# Helpers chung
# ----------------------------
def _dt(v):
    if not v:
        return None
    return v.isoformat() if isinstance(v, datetime) else str(v)


def _normalize_role(v: Any) -> str:
    if not v:
        return ""
    return str(v).strip().upper()


def _infer_role_from_batch_code(code: str) -> str:
    """
    ✅ FIX: suy luận tầng từ batch_code để chống lỗi Clone giữ owner_role=FARM.
    Ví dụ:
      GARMENT-001                          -> FARM
      GARMENT-001-SUPPLIER-...             -> SUPPLIER
      GARMENT-001-...-MANUFACTURER-...     -> MANUFACTURER
      GARMENT-001-...-BRAND-...            -> BRAND
    """
    c = _normalize_role(code)

    # ưu tiên các tầng "cao" trước để tránh match nhầm
    if "BRAND" in c:
        return "BRAND"
    if "MANUFACTURER" in c or "-MFG-" in c or " MFG " in c or c.endswith("-MFG"):
        return "MANUFACTURER"
    if "SUPPLIER" in c:
        return "SUPPLIER"
    if "FARM" in c:
        return "FARM"
    return "FARM"


def _choose_effective_role(batch_code: str, role_from_db: str) -> str:
    """
    ✅ FIX: Nếu role DB bị sai (hay gặp: FARM) nhưng batch_code thể hiện tầng khác,
    thì override theo batch_code.
    """
    db_role = _normalize_role(role_from_db)
    inferred = _infer_role_from_batch_code(batch_code)

    # nếu db_role rỗng -> dùng inferred
    if not db_role:
        return inferred

    # nếu db_role là FARM nhưng inferred là tầng khác -> override
    if db_role == "FARM" and inferred != "FARM":
        return inferred

    # nếu db_role không thuộc tập hợp known -> dùng inferred
    if db_role not in {"FARM", "SUPPLIER", "MANUFACTURER", "BRAND"}:
        return inferred

    # nếu db_role khác inferred (và inferred rõ ràng), ưu tiên inferred để chống clone lỗi
    if inferred in {"SUPPLIER", "MANUFACTURER", "BRAND"} and db_role != inferred:
        return inferred

    return db_role


# ----------------------------
# Blockchain anchor (proof)
# ----------------------------
async def _get_anchor(db: AsyncSession, ref: str):
    # 1) Ưu tiên bảng mới blockchain_proofs
    sql_bp = """
    SELECT
        tenant_id,
        batch_code,
        network,
        tx_hash,
        block_number,
        root_hash,
        status,
        created_at,
        contract_address
    FROM blockchain_proofs
    WHERE batch_code = :r
    ORDER BY created_at DESC
    LIMIT 1
    """
    rs = await db.execute(text(sql_bp), {"r": ref})
    row = rs.fetchone()
    if row:
        m = row._mapping
        return {
            "tenant_id": m["tenant_id"],
            "ref": m["batch_code"],
            "tx_hash": m["tx_hash"],
            "network": m["network"],
            "root_hash": m["root_hash"],
            "block_number": m["block_number"],
            "status": m["status"],
            "created_at": _dt(m["created_at"]),
            "meta": {},
            "ipfs_cid": None,
            "ipfs_gateway": None,
        }

    # 2) Fallback: blockchain_anchors cũ
    sql_ba = """
    SELECT id, tenant_id, ref, tx_hash, network, batch_hash, block_number,
           status, created_at, meta, ipfs_cid
    FROM blockchain_anchors
    WHERE ref = :r
    ORDER BY id DESC
    LIMIT 1
    """
    rs2 = await db.execute(text(sql_ba), {"r": ref})
    row2 = rs2.fetchone()
    if not row2:
        return None

    m2 = row2._mapping
    return {
        "tenant_id": m2["tenant_id"],
        "ref": m2["ref"],
        "tx_hash": m2["tx_hash"],
        "network": m2["network"],
        "root_hash": m2["batch_hash"],
        "block_number": m2["block_number"],
        "status": m2["status"],
        "created_at": _dt(m2["created_at"]),
        "meta": json.loads(m2["meta"] or "{}"),
        "ipfs_cid": m2["ipfs_cid"],
        "ipfs_gateway": f"https://ipfs.io/ipfs/{m2['ipfs_cid']}" if m2["ipfs_cid"] else None,
    }


# ----------------------------
# Batch + Product
# ----------------------------
async def _get_batch(db: AsyncSession, code: str):
    sql = """
    SELECT
        b.tenant_id, b.code, b.product_code, b.mfg_date, b.country,
        b.quantity, b.unit,
        p.name AS product_name,
        NULL AS product_brand,   -- bảng products hiện chưa có cột brand
        NULL AS product_gtin     -- bảng products hiện chưa có cột gtin
    FROM batches b
    LEFT JOIN products p
      ON p.code = b.product_code AND p.tenant_id = b.tenant_id
    WHERE b.code = :c
    LIMIT 1
    """
    rs = await db.execute(text(sql), {"c": code})
    row = rs.fetchone()
    if not row:
        return None
    m = row._mapping
    return {
        "tenant_id": m["tenant_id"],
        "batch_code": m["code"],
        "product_code": m["product_code"],
        "mfg_date": _dt(m["mfg_date"]),
        "country": m["country"],
        "quantity": float(m["quantity"]) if m["quantity"] is not None else None,
        "unit": m["unit"],
        "product": {
            "name": m["product_name"],
            "brand": m["product_brand"],
            "gtin": m["product_gtin"],
        },
    }


# ----------------------------
# EPCIS Events – LẤY ĐỦ CHUỖI FARM → SUPPLIER → MFG → BRAND
# ----------------------------
async def _get_events(db: AsyncSession, tenant_id: int, final_code: str):
    """
    Lấy toàn bộ EPCIS events cho cả chuỗi batch:
    - Mọi batch có code là prefix của final_code
      (vd: GARMENT-002, GARMENT-002-SUPPLIER-..., ...-MANUFACTURER-..., ...-BRAND-...)
    - Kèm owner_role của batch để biết event thuộc tầng nào.
    - ✅ FIX: Nếu owner_role bị sai do clone (thường FARM), sẽ suy luận từ batch_code.
    """
    sql = """
    SELECT
        e.id,
        e.event_id,
        e.event_type,
        e.action,
        e.product_code,
        e.biz_step,
        e.disposition,
        e.doc_bundle_id,
        e.event_time,
        e.biz_location,
        e.read_point,

        e.epc_list,
        e.ilmd,
        e.extensions,
        e.event_time_zone_offset,
        e.biz_transaction_list,
        e.context,
        e.event_hash,
        e.vc_hash_hex,
        e.verified,
        e.verify_error,
        e.raw_payload,

        b.owner_role AS owner_role,   -- tầng: FARM / SUPPLIER / MANUFACTURER / BRAND
        b.code       AS batch_code    -- batch cụ thể của event
    FROM epcis_events e
    JOIN batches b
      ON b.code = e.batch_code
     AND b.tenant_id = e.tenant_id
    WHERE e.tenant_id = :t
      -- mọi batch mà code là prefix của final_code
      AND :final_code LIKE e.batch_code || '%'
    ORDER BY e.event_time ASC, e.id ASC
    """

    rs = await db.execute(text(sql), {"t": tenant_id, "final_code": final_code})
    rows = rs.fetchall()

    def _json_or_raw(v):
        """Cột JSON có thể đang là text, dict hoặc list – chuẩn hoá về object."""
        if v is None:
            return None
        if isinstance(v, (dict, list)):
            return v
        try:
            return json.loads(v)
        except Exception:
            return v

    out: list[dict[str, Any]] = []
    for r in rows:
        m = r._mapping

        batch_code = m["batch_code"]
        owner_role_db = m["owner_role"]
        owner_role_effective = _choose_effective_role(batch_code, owner_role_db)

        out.append(
            {
                "id": m["id"],
                "event_id": m["event_id"],
                "event_type": m["event_type"],
                "action": m["action"],
                "product_code": m["product_code"],
                "biz_step": m["biz_step"],
                "disposition": m["disposition"],
                "doc_bundle_id": m["doc_bundle_id"],
                "event_time": _dt(m["event_time"]),
                "biz_location": m["biz_location"],
                "read_point": m["read_point"],

                "epc_list": _json_or_raw(m["epc_list"]),
                "ilmd": _json_or_raw(m["ilmd"]),
                "extensions": _json_or_raw(m["extensions"]),
                "event_time_zone_offset": m["event_time_zone_offset"],
                "biz_transaction_list": _json_or_raw(m["biz_transaction_list"]),
                "context": _json_or_raw(m["context"]),
                "event_hash": m["event_hash"],
                "vc_hash_hex": m["vc_hash_hex"],
                "verified": m["verified"],
                "verify_error": m["verify_error"],
                "raw_payload": m["raw_payload"],

                # thông tin để DppPage nhóm theo tầng
                "owner_role": owner_role_effective,      # ✅ FIX: role đã được sửa/chuẩn hoá
                "batch_owner_role": owner_role_db,       # (optional) giữ lại để debug
                "batch_code": batch_code,
            }
        )
    return out


# ----------------------------
# Documents gắn với batch (qua doc_bundle_id)
# ----------------------------
async def _get_docs(db: AsyncSession, tenant_id: int, code: str):
    sql = """
    SELECT d.id, d.file_name, d.file_hash, d.doc_bundle_id,
           c.status AS vc_status, c.hash_hex AS vc_hash
    FROM documents d
    LEFT JOIN credentials c
      ON c.hash_hex = d.file_hash
    WHERE d.tenant_id = :t
      AND d.doc_bundle_id = (
        SELECT doc_bundle_id
        FROM epcis_events
        WHERE tenant_id = :t
          AND batch_code = :b
        ORDER BY created_at DESC
        LIMIT 1
      )
    """
    rs = await db.execute(text(sql), {"t": tenant_id, "b": code})
    rows = rs.fetchall()
    out: list[dict[str, Any]] = []
    for r in rows:
        m = r._mapping
        out.append(
            {
                "id": m["id"],
                "file_name": m["file_name"],
                "file_hash": m["file_hash"],
                "doc_bundle_id": m["doc_bundle_id"],
                "vc_status": m["vc_status"],
                "vc_hash": m["vc_hash"],
            }
        )
    return out


# ----------------------------
# PUBLIC API: DPP Landing (lite / full)
# ----------------------------
@router.get("/dpp/{ref}")
async def dpp_public(
    ref: str,
    mode: str = Query("lite", description="lite or full"),
    db: AsyncSession = Depends(get_db),
):
    """
    /api/public/dpp/{ref}?mode=lite|full

    - lite: chỉ trả thông tin blockchain (proof)
    - full: batch + blockchain + EPCIS events (đầy đủ cột) + documents
    """
    # 1) Blockchain proof
    anchor = await _get_anchor(db, ref)
    if not anchor:
        raise HTTPException(404, "No blockchain anchor found")

    # Lite mode -> chỉ blockchain + ipfs
    if mode == "lite":
        return anchor

    # 2) full mode -> batch + events + docs
    batch = await _get_batch(db, ref)
    if not batch:
        raise HTTPException(404, "Batch not found")

    tenant_id = batch["tenant_id"]
    events = await _get_events(db, tenant_id, ref)
    docs = await _get_docs(db, tenant_id, ref)

    # dpp_json: payload tổng hợp (cho dev / debug, frontend vẫn render chi tiết từng field)
    dpp_json = {
        "id": f"DPP-{ref}",
        "product": batch["product"],
        "batch": batch,
        "events": events,
        "documents": docs,
        "blockchain": anchor,
    }

    return {
        "batch": batch,
        "blockchain": anchor,
        "events": events,
        "documents": docs,
        "dpp_json": dpp_json,
    }


# ----------------------------
# DPP Registry list (dpp-list)
# ----------------------------
@router.get("/dpp-list")
async def get_dpp_list(db: AsyncSession = Depends(get_db)):
    """
    Danh sách các batch đã có proof trên blockchain để hiển thị ở DppListPage.
    """
    sql = """
        SELECT
            bp.tenant_id,
            bp.batch_code AS ref,
            bp.network,
            bp.tx_hash,
            bp.block_number,
            bp.root_hash,
            bp.status,
            bp.published_at,
            bp.contract_address,
            ba.ipfs_cid,
            b.product_code,
            p.name AS product_name,
            NULL  AS product_brand
        FROM blockchain_proofs bp
        LEFT JOIN blockchain_anchors ba
          ON ba.ref = bp.batch_code
         AND ba.tenant_id = bp.tenant_id
        LEFT JOIN batches b
          ON b.code = bp.batch_code
         AND b.tenant_id = bp.tenant_id
        LEFT JOIN products p
          ON p.code = b.product_code
         AND p.tenant_id = b.tenant_id
        ORDER BY bp.created_at DESC
    """
    res = await db.execute(text(sql))
    return res.mappings().all()


# ----------------------------
# Route legacy tương thích backend cũ
# ----------------------------
@router.get("/dpp-legacy/{batch_code}")
async def public_dpp_compatible(batch_code: str, db: AsyncSession = Depends(get_db)):
    """
    Compatible với old frontend: /api/public/dpp-legacy/{batch_code}
    Dùng chung helper _build_and_optionally_upload_dpp ở blockchain.py
    """
    try:
        return await _build_and_optionally_upload_dpp(db, batch_code, upload=False)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(500, f"Failed to build DPP: {str(e)}")
