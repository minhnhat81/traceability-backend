from __future__ import annotations

import json
import hashlib
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Body, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.core.db import get_db
from app.security import verify_jwt, check_permission

import logging
import os
import requests
from fastapi.responses import JSONResponse

logger = logging.getLogger("uvicorn.error")

router = APIRouter(prefix="/api/blockchain", tags=["blockchain"])

WEB3_STORAGE_TOKEN = os.getenv("WEB3_STORAGE_TOKEN")


# =========================================================
# Helpers
# =========================================================

def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _hash_events(events: List[dict]) -> str:
    payload = json.dumps(events, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


async def _fetch_epcis_events(db: AsyncSession, batch_code: str) -> List[dict]:
    result = await db.execute(
        text("""
            SELECT id, tenant_id, event_type, batch_code, product_code, event_time,
                   action, biz_step, disposition, event_id, doc_bundle_id,
                   read_point, biz_location, created_at
            FROM epcis_events
            WHERE batch_code = :b
            ORDER BY created_at ASC, id ASC
        """),
        {"b": batch_code},
    )
    rows = result.fetchall()

    events: List[dict] = []
    for r in rows:
        m = r._mapping
        events.append({
            "id": m["id"],
            "tenant_id": m["tenant_id"],
            "type": m["event_type"],
            "batch_code": m["batch_code"],
            "product_code": m["product_code"],
            "eventTime": str(m["event_time"]) if m["event_time"] else None,
            "action": m["action"],
            "bizStep": m["biz_step"],
            "disposition": m["disposition"],
            "event_id": m["event_id"],
            "doc_bundle_id": m["doc_bundle_id"],
            "readPoint": m["read_point"],
            "bizLocation": m["biz_location"],
            "created_at": str(m["created_at"]) if m["created_at"] else None,
        })
    return events


# =========================================================
# FIXED: Get blockchain anchor (fallback to blockchain_proofs)
# =========================================================
async def _get_anchor(db: AsyncSession, batch_code: str):
    # Ưu tiên lấy blockchain_anchors (logic gốc)
    result = await db.execute(
        text("""
            SELECT id, tenant_id, anchor_type, ref, tx_hash, network, meta,
                   bundle_id, batch_hash, block_number, status, created_at, updated_at,
                   ipfs_cid
            FROM blockchain_anchors
            WHERE ref = :r
            ORDER BY id DESC
            LIMIT 1
        """),
        {"r": batch_code},
    )
    row = result.fetchone()
    if row:
        return row

    # Fallback sang blockchain_proofs
    result = await db.execute(
        text("""
            SELECT
                NULL::integer AS id,
                tenant_id,
                'epcis_batch' AS anchor_type,
                batch_code AS ref,
                tx_hash,
                network,
                '{}'::jsonb AS meta,
                NULL AS bundle_id,
                root_hash AS batch_hash,
                block_number,
                status,
                published_at AS created_at,
                published_at AS updated_at,
                NULL AS ipfs_cid
            FROM blockchain_proofs
            WHERE batch_code = :r
            ORDER BY id DESC
            LIMIT 1
        """),
        {"r": batch_code},
    )
    return result.fetchone()


async def _fetch_batch(db: AsyncSession, batch_code: str) -> Optional[Dict[str, Any]]:
    res = await db.execute(
        text("""
            SELECT
                id,
                tenant_id,
                code,
                product_code,
                material_type,
                country,
                mfg_date,
                quantity,
                unit,
                owner_role,
                status,
                description,
                origin_farm_id,
                created_at
            FROM batches
            WHERE code = :c
            LIMIT 1
        """),
        {"c": batch_code},
    )
    row = res.fetchone()
    return dict(row._mapping) if row else None


# =========================================================
# Build DPP JSON
# =========================================================
def _build_dpp_json(batch, events, anchor):
    product = {
        "batch_code": batch.get("code"),
        "product_code": batch.get("product_code"),
        "description": batch.get("description"),
        "material_type": batch.get("material_type"),
        "country_of_origin": batch.get("country"),
        "manufacturing_date": batch.get("mfg_date").isoformat()
        if batch.get("mfg_date") else None,
        "quantity": float(batch.get("quantity") or 0),
        "unit": batch.get("unit"),
        "owner_role": batch.get("owner_role"),
    }

    production = {
        "tenant_id": batch.get("tenant_id"),
        "origin_farm_id": batch.get("origin_farm_id"),
        "status": batch.get("status"),
        "created_at": batch.get("created_at").isoformat()
        if batch.get("created_at") else None,
    }

    traceability = {
        "event_count": len(events),
        "first_event_time": events[0].get("eventTime") if events else None,
        "last_event_time": events[-1].get("eventTime") if events else None,
    }

    anchor_meta = {}
    ipfs_cid = None
    if anchor:
        m = anchor._mapping if hasattr(anchor, "_mapping") else anchor
        raw_meta = m.get("meta")
        if isinstance(raw_meta, dict):
            anchor_meta = raw_meta
        elif raw_meta:
            try:
                anchor_meta = json.loads(raw_meta)
            except:
                anchor_meta = {}
        ipfs_cid = m.get("ipfs_cid")

    blockchain = {
        "status": (anchor or {}).get("status") or "NONE",
        "network": (anchor or {}).get("network"),
        "tx_hash": (anchor or {}).get("tx_hash"),
        "block_number": (anchor or {}).get("block_number"),
        "root_hash": (anchor or {}).get("batch_hash"),
        "anchor_type": (anchor or {}).get("anchor_type"),
        "ipfs_cid": ipfs_cid,
        "explorer_url": (
            f"https://amoy.polygonscan.com/tx/{(anchor or {}).get('tx_hash')}"
            if (anchor or {}).get("network") in ("polygon", "polygon-amoy")
            and (anchor or {}).get("tx_hash")
            else None
        ),
        "meta": anchor_meta,
    }

    ipfs = {
        "cid": ipfs_cid,
        "gateway_url": f"https://{ipfs_cid}.ipfs.w3s.link" if ipfs_cid else None,
    }

    return {
        "dpp_version": "1.0",
        "spec": "eu-dpp-minimal",
        "generated_at": _now_iso(),
        "batch_code": batch.get("code"),
        "parts": {
            "product": product,
            "production": production,
            "traceability": traceability,
            "epcis_events": events,
            "blockchain": blockchain,
            "ipfs": ipfs,
        },
    }
# =========================================================
# Upload DPP → Web3.Storage
# =========================================================
def _upload_to_web3_storage(dpp: Dict[str, Any]) -> Optional[str]:
    if not WEB3_STORAGE_TOKEN:
        logger.warning("[DPP] WEB3_STORAGE_TOKEN not set – skip IPFS upload")
        return None

    try:
        data = json.dumps(dpp, sort_keys=True, separators=(",", ":")).encode("utf-8")

        headers = {"Authorization": f"Bearer {WEB3_STORAGE_TOKEN}"}
        files = {"file": ("dpp.json", data, "application/json")}

        resp = requests.post(
            "https://api.web3.storage/upload",
            headers=headers,
            files=files,
            timeout=60,
        )
        resp.raise_for_status()

        js = resp.json()
        cid = js.get("cid") or js.get("value", {}).get("cid")
        logger.info(f"[DPP] Uploaded to Web3.Storage cid={cid}")
        return cid

    except Exception as e:
        logger.exception(f"[DPP] IPFS upload failed: {e}")
        return None


# =========================================================
# Build + optionally upload DPP
# =========================================================
async def _build_and_optionally_upload_dpp(
    db: AsyncSession, batch_code: str, upload: bool = False
):
    batch = await _fetch_batch(db, batch_code)
    if not batch:
        raise HTTPException(404, f"Batch {batch_code} not found")

    events = await _fetch_epcis_events(db, batch_code)
    anchor_row = await _get_anchor(db, batch_code)
    anchor_dict = None
    if anchor_row:
        anchor_dict = anchor_row._mapping if hasattr(anchor_row, "_mapping") else anchor_row

    dpp = _build_dpp_json(batch, events, anchor_dict)

    if upload:
        cid = _upload_to_web3_storage(dpp)
        if cid and anchor_row:
            await db.execute(
                text("""
                    UPDATE blockchain_anchors
                    SET ipfs_cid = :cid,
                        meta = COALESCE(meta, '{}'::jsonb) || :m::jsonb,
                        updated_at = NOW()
                    WHERE id = :id
                """),
                {
                    "cid": cid,
                    "m": json.dumps({"ipfs_cid": cid, "dpp_version": "1.0"}),
                    "id": anchor_row._mapping["id"],
                },
            )
            await db.commit()

            dpp["parts"]["blockchain"]["ipfs_cid"] = cid
            dpp["parts"]["ipfs"]["cid"] = cid
            dpp["parts"]["ipfs"]["gateway_url"] = f"https://{cid}.ipfs.w3s.link"

    return dpp


# =========================================================
# GET /proof → dùng bảng blockchain_proofs mới
# =========================================================
@router.get("/proof")
async def get_proof(
    batch_code: str = Query(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id") or 1

    q = await db.execute(
        text("""
            SELECT
              batch_code,
              network,
              tx_hash,
              block_number,
              root_hash,
              status,
              contract_address,
              published_at
            FROM blockchain_proofs
            WHERE tenant_id = :t AND batch_code = :b
            ORDER BY created_at DESC
            LIMIT 1
        """),
        {"t": tenant_id, "b": batch_code},
    )

    row = q.mappings().first()
    if not row:
        return {"batch_code": batch_code, "status": "NONE"}

    return {
        "batch_code": row["batch_code"],
        "network": row["network"],
        "tx_hash": row["tx_hash"],
        "block_number": row["block_number"],
        "root_hash": row["root_hash"],
        "status": row["status"],
        "published_at": row["published_at"],
        "contract_address": row["contract_address"],
    }


# =========================================================
# POST /publish — GIỮ NGUYÊN LOGIC + thêm ghi blockchain_proofs
# =========================================================
@router.post("/publish")
async def publish_epcis(
    body: dict = Body(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    batch_code = (body or {}).get("batch_code")
    if not batch_code:
        raise HTTPException(400, "Missing batch_code")

    # Permission (giữ nguyên)
    ok = True
    try:
        ok = check_permission(
            db,
            user,
            "blockchain",
            "create",
            {"ref": batch_code},
            path="/api/blockchain/publish",
            method="POST",
        )
    except Exception:
        ok = True

    if not ok:
        raise HTTPException(403, "permission denied")

    # EPCIS events
    events = await _fetch_epcis_events(db, batch_code)
    if not events:
        raise HTTPException(404, "No EPCIS events found for this batch")

    # Hash logic (giữ nguyên)
    root_hash = _hash_events(events)

    fake_tx_hash = "0x" + hashlib.sha256((batch_code + root_hash).encode()).hexdigest()[:64]
    fake_block = (
        int(hashlib.sha256(fake_tx_hash.encode()).hexdigest(), 16) % 5_000_000 + 1
    )

    # Log polygon_logs (giữ nguyên)
    await db.execute(
        text("""
            INSERT INTO polygon_logs(tx_hash, method, params, result)
            VALUES (:tx, :m, :p, :r)
        """),
        {
            "tx": fake_tx_hash,
            "m": "storeProof",
            "p": json.dumps({"batch_code": batch_code, "root_hash": root_hash}),
            "r": json.dumps({
                "tx_hash": fake_tx_hash,
                "block_number": fake_block,
                "ts": _now_iso(),
            }),
        },
    )

    # Insert / update blockchain_anchors (giữ nguyên)
    existing = await _get_anchor(db, batch_code)
    if existing and existing._mapping["id"] is not None:
        await db.execute(
            text("""
                UPDATE blockchain_anchors
                SET batch_hash=:h, tx_hash=:tx, block_number=:bn,
                    network='polygon', status='CONFIRMED', updated_at=NOW(),
                    meta = COALESCE(meta,'{}'::jsonb) || :meta
                WHERE id=:id
            """),
            {
                "id": existing._mapping["id"],
                "h": root_hash,
                "tx": fake_tx_hash,
                "bn": fake_block,
                "meta": json.dumps({"events": len(events)}),
            },
        )
    else:
        await db.execute(
            text("""
                INSERT INTO blockchain_anchors(
                    tenant_id, anchor_type, ref, tx_hash, network, meta,
                    bundle_id, batch_hash, block_number, status, created_at, updated_at
                ) VALUES (
                    :tid, 'epcis_batch', :ref, :tx, 'polygon', :meta,
                    NULL, :h, :bn, 'CONFIRMED', NOW(), NOW()
                )
            """),
            {
                "tid": (user or {}).get("tenant_id", 1),
                "ref": batch_code,
                "tx": fake_tx_hash,
                "meta": json.dumps({"events": len(events)}),
                "h": root_hash,
                "bn": fake_block,
            },
        )

    # Giữ polygon_anchors cũ
    await db.execute(
        text("""
            INSERT INTO polygon_anchors(tx_hash, anchor_type, ref_id, status, meta)
            VALUES (:tx, 'epcis_batch', :ref, 'CONFIRMED', :meta)
        """),
        {"tx": fake_tx_hash, "ref": batch_code, "meta": json.dumps({"root_hash": root_hash})},
    )

    # ===============================================
    # ⭐ NEW: Ghi vào bảng blockchain_proofs
    # ===============================================
    await db.execute(
        text("""
            INSERT INTO blockchain_proofs(
                tenant_id, batch_code, network, tx_hash,
                block_number, root_hash, status, contract_address,
                published_at, created_at
            ) VALUES (
                :tid, :bc, 'polygon', :tx,
                :bn, :rh, 'CONFIRMED', NULL,
                NOW(), NOW()
            )
        """),
        {
            "tid": (user or {}).get("tenant_id", 1),
            "bc": batch_code,
            "tx": fake_tx_hash,
            "bn": fake_block,
            "rh": root_hash,
        },
    )

    await db.commit()

    # Build DPP + upload IPFS
    dpp = await _build_and_optionally_upload_dpp(db, batch_code, upload=True)

    return {
        "ok": True,
        "batch_code": batch_code,
        "root_hash": root_hash,
        "network": "polygon",
        "tx_hash": fake_tx_hash,
        "block_number": fake_block,
        "published_at": _now_iso(),
        "status": "CONFIRMED",
        "ipfs_cid": dpp["parts"]["ipfs"]["cid"],
        "dpp": dpp,
    }
# =========================================================
# POST /verify – giữ logic gốc
# =========================================================
@router.post("/verify")
async def verify_anchor(
    body: dict = Body(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    batch_code = (body or {}).get("batch_code")
    if not batch_code:
        raise HTTPException(400, "Missing batch_code")

    anchor = await _get_anchor(db, batch_code)
    if not anchor:
        raise HTTPException(404, "Anchor not found for this batch")

    events = await _fetch_epcis_events(db, batch_code)
    if not events:
        raise HTTPException(404, "No EPCIS events found for this batch")

    current_hash = _hash_events(events)
    m = anchor._mapping
    stored_hash = m["batch_hash"]
    verified = stored_hash is not None and stored_hash == current_hash

    await db.execute(
        text("""
            UPDATE blockchain_anchors
            SET status=:st, updated_at=NOW()
            WHERE id=:id
        """),
        {"st": "CONFIRMED" if verified else "FAILED", "id": m["id"]},
    )
    await db.commit()

    return {
        "ok": verified,
        "batch_code": batch_code,
        "root_hash": stored_hash,
        "current_hash": current_hash,
        "status": "CONFIRMED" if verified else "FAILED",
        "checked_at": _now_iso(),
    }


# =========================================================
# NEW: Authenticated DPP API (admin/internal)
# =========================================================
@router.get("/dpp")
async def get_dpp(
    batch_code: str,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    Internal / authenticated DPP JSON
    """
    try:
        dpp = await _build_and_optionally_upload_dpp(db, batch_code, upload=False)
        return dpp
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"[DPP] get_dpp error: {e}")
        raise HTTPException(500, "Failed to build DPP")


# =========================================================
# NEW: Public DPP API (QR / website landing page)
# =========================================================
@router.get("/public/dpp/{batch_code}")
async def public_dpp(batch_code: str, db: AsyncSession = Depends(get_db)):
    """
    Public, no authentication.
    Used by QR on the garment.
    """
    try:
        dpp = await _build_and_optionally_upload_dpp(db, batch_code, upload=False)
        return dpp
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.exception(f"[DPP] public_dpp error: {e}")
        raise HTTPException(500, "Failed to build DPP")


# =========================================================
# Simulated Fabric Invoke – giữ nguyên
# =========================================================
@router.post("/fabric/invoke")
async def invoke_fabric(
    body: dict = Body(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    Giả lập gửi transaction lên Fabric
    """
    try:
        logger.info(f"[Fabric] Fake invoke called with body={body}")

        channel = body.get("channel", "mychannel")
        chaincode = body.get("chaincode", "tracecc")
        func = body.get("function")
        args = body.get("args", [])

        if not func:
            raise HTTPException(400, "Missing 'function'")

        tx_id = hashlib.sha256(
            (func + json.dumps(args) + _now_iso()).encode()
        ).hexdigest()[:16]

        fake_response = {
            "ok": True,
            "network": "fabric",
            "channel": channel,
            "chaincode": chaincode,
            "function": func,
            "args": args,
            "tx_id": tx_id,
            "status": "SUCCESS",
            "timestamp": _now_iso(),
            "user": getattr(user, "email", "anonymous"),
        }

        logger.info(f"[Fabric] SUCCESS: {fake_response}")
        return JSONResponse(fake_response)

    except Exception as e:
        logger.error(f"[Fabric] Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


# =========================================================
# Fabric Events ingest
# =========================================================
@router.post("/fabric/events")
async def fabric_event_ingest(
    payload: dict = Body(...),
    db: AsyncSession = Depends(get_db)
):
    tx_id = payload.get("txId") or payload.get("transactionId")
    block_number = payload.get("blockNumber") or 0
    chaincode_id = payload.get("chaincodeId") or ""
    event_name = payload.get("eventName") or ""
    ev_payload = payload.get("payload") or {}

    await db.execute(
        text("""
            INSERT INTO fabric_events(tx_id, block_number, chaincode_id, event_name, payload, status, ts)
            VALUES (:tx, :bn, :cc, :ev, :pl, 'RECEIVED', NOW())
        """),
        {
            "tx": tx_id,
            "bn": block_number,
            "cc": chaincode_id,
            "ev": event_name,
            "pl": json.dumps(ev_payload),
        },
    )
    await db.commit()

    return {"ok": True}


# =========================================================
# Observer latest Fabric events
# =========================================================
@router.get("/observer/latest")
async def observer_latest(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT id, tx_id, block_number, event_name, ts
            FROM fabric_events
            ORDER BY id DESC
            LIMIT 50
        """)
    )
    rows = result.fetchall()

    return [
        {
            "id": r[0],
            "tx_id": r[1],
            "block_number": r[2],
            "event_name": r[3],
            "ts": str(r[4]),
        }
        for r in rows
    ]


# =========================================================
# /anchor batch_code – giữ nguyên
# =========================================================
@router.post("/anchor")
async def anchor_batch_code(
    batch_code: str,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    events = await _fetch_epcis_events(db, batch_code)
    if not events:
        raise HTTPException(404, "No EPCIS events found")

    root_hash = _hash_events(events)

    fake_tx_hash = "0x" + hashlib.sha256((batch_code + root_hash).encode()).hexdigest()[:64]
    fake_block = (
        int(hashlib.sha256(fake_tx_hash.encode()).hexdigest(), 16) % 5_000_000 + 1
    )

    # Insert to anchors
    await db.execute(
        text("""
            INSERT INTO blockchain_anchors(
                tenant_id, anchor_type, ref, tx_hash, network, meta,
                batch_hash, block_number, status, created_at, updated_at
            ) VALUES (
                :tid, 'batch', :ref, :tx, 'polygon', :meta,
                :h, :bn, 'CONFIRMED', NOW(), NOW()
            )
        """),
        {
            "tid": user.get("tenant_id"),
            "ref": batch_code,
            "tx": fake_tx_hash,
            "meta": json.dumps({"events": len(events)}),
            "h": root_hash,
            "bn": fake_block,
        },
    )

    await db.commit()

    return {"ok": True, "ref": batch_code}
