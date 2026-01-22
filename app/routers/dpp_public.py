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
    Suy luận tầng từ batch_code để chống lỗi Clone giữ owner_role=FARM
    """
    c = _normalize_role(code)

    if "BRAND" in c:
        return "BRAND"
    if "MANUFACTURER" in c or "-MFG-" in c or c.endswith("-MFG"):
        return "MANUFACTURER"
    if "SUPPLIER" in c:
        return "SUPPLIER"
    return "FARM"


def _choose_effective_role(batch_code: str, role_from_db: str) -> str:
    db_role = _normalize_role(role_from_db)
    inferred = _infer_role_from_batch_code(batch_code)

    if not db_role:
        return inferred

    if db_role == "FARM" and inferred != "FARM":
        return inferred

    if db_role not in {"FARM", "SUPPLIER", "MANUFACTURER", "BRAND"}:
        return inferred

    if inferred in {"SUPPLIER", "MANUFACTURER", "BRAND"} and db_role != inferred:
        return inferred

    return db_role


# ----------------------------
# Blockchain anchor (proof)
# ----------------------------
async def _get_anchor(db: AsyncSession, ref: str):
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
        NULL AS product_brand,
        NULL AS product_gtin
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
# EPCIS Events – FIX CLONE CHUỖI
# ----------------------------
async def _get_events(db: AsyncSession, tenant_id: int, final_code: str):
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

        b.owner_role AS owner_role,
        b.code       AS batch_code
    FROM epcis_events e
    JOIN batches b
      ON b.code = e.batch_code
     AND b.tenant_id = e.tenant_id
    WHERE e.tenant_id = :t
      -- ✅ FIX QUAN TRỌNG
      AND e.batch_code LIKE :final_code || '%'
    ORDER BY e.event_time ASC, e.id ASC
    """

    rs = await db.execute(text(sql), {"t": tenant_id, "final_code": final_code})
    rows = rs.fetchall()

    def _json_or_raw(v):
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
                "owner_role": owner_role_effective,
                "batch_owner_role": owner_role_db,
                "batch_code": batch_code,
            }
        )
    return out


# ----------------------------
# Documents
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
    return [
        {
            "id": r._mapping["id"],
            "file_name": r._mapping["file_name"],
            "file_hash": r._mapping["file_hash"],
            "doc_bundle_id": r._mapping["doc_bundle_id"],
            "vc_status": r._mapping["vc_status"],
            "vc_hash": r._mapping["vc_hash"],
        }
        for r in rows
    ]


# ----------------------------
# PUBLIC API
# ----------------------------
@router.get("/dpp/{ref}")
async def dpp_public(
    ref: str,
    mode: str = Query("lite"),
    db: AsyncSession = Depends(get_db),
):
    anchor = await _get_anchor(db, ref)
    if not anchor:
        raise HTTPException(404, "No blockchain anchor found")

    if mode == "lite":
        return anchor

    batch = await _get_batch(db, ref)
    if not batch:
        raise HTTPException(404, "Batch not found")

    tenant_id = batch["tenant_id"]
    events = await _get_events(db, tenant_id, ref)
    docs = await _get_docs(db, tenant_id, ref)

    return {
        "batch": batch,
        "blockchain": anchor,
        "events": events,
        "documents": docs,
        "dpp_json": {
            "id": f"DPP-{ref}",
            "batch": batch,
            "events": events,
            "documents": docs,
            "blockchain": anchor,
        },
    }


# ----------------------------
# Legacy
# ----------------------------
@router.get("/dpp-legacy/{batch_code}")
async def public_dpp_compatible(batch_code: str, db: AsyncSession = Depends(get_db)):
    try:
        return await _build_and_optionally_upload_dpp(db, batch_code, upload=False)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500, f"Failed to build DPP: {str(e)}")
