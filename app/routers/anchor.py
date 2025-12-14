from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from datetime import datetime, timezone
from typing import List, Optional, Tuple, Dict, Any
import hashlib
import json
import re

from app.core.db import get_db
from app.security import verify_jwt

router = APIRouter(prefix="/api/anchor", tags=["digital-anchor"])

# =========================
# Helpers
# =========================

def _sha256_hex(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def _safe_hex_to_bytes(h: str) -> bytes:
    """
    Chuẩn hóa và kiểm tra chuỗi hex hợp lệ.
    """
    if not h or not isinstance(h, str):
        raise ValueError(f"Invalid hash value (None or not string): {h!r}")
    h = h.strip().lower()
    if h.startswith("0x"):
        h = h[2:]
    if not re.fullmatch(r"[0-9a-f]+", h):
        raise ValueError(f"Non-hex character in hash: {h}")
    return bytes.fromhex(h)


def _merkle_root_hex(leaves: List[str]) -> str:
    """
    Tính Merkle root an toàn từ danh sách hex-string.
    Bỏ qua phần tử rỗng / None và báo lỗi nếu gặp giá trị không hợp lệ.
    """
    import re

    if not leaves:
        return _sha256_hex(b"")

    clean = []
    for h in leaves:
        if not h or not isinstance(h, str):
            print(f"[WARN] ⚠️ Invalid hash (None or not string): {h!r}")
            continue
        h = h.strip().lower()
        if h.startswith("0x"):
            h = h[2:]
        if not re.fullmatch(r"[0-9a-f]+", h):
            print(f"[WARN] ⚠️ Non-hex characters in hash: {h!r}")
            continue
        try:
            clean.append(bytes.fromhex(h))
        except Exception as e:
            print(f"[WARN] ⚠️ Skipping invalid hash {h!r}: {e}")

    if not clean:
        raise ValueError("No valid hex leaves to build Merkle tree")

    level = clean
    while len(level) > 1:
        nxt = []
        for i in range(0, len(level), 2):
            left = level[i]
            right = level[i + 1] if i + 1 < len(level) else left
            nxt.append(hashlib.sha256(left + right).digest())
        level = nxt

    return level[0].hex()



async def _get_default_chain(db: AsyncSession, tenant_id: int) -> Dict[str, Any] | None:
    """
    Lấy cấu hình blockchain mặc định của tenant từ bảng configs_blockchain.
    """
    rs = await db.execute(
        text(
            """
            SELECT id, tenant_id, network, rpc_url, abi_id, is_default
            FROM configs_blockchain
            WHERE tenant_id=:t
            ORDER BY is_default DESC, id ASC
            LIMIT 1
            """
        ),
        {"t": tenant_id},
    )
    row = rs.first()
    if not row:
        return None
    return dict(zip(rs.keys(), row))


async def _load_bundle_data(
    db: AsyncSession, tenant_id: int, bundle_id: str
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    Trả về (docs, events) cho một bundle.
    - docs: phải có file_hash, vc_hash_hex
    - events: phải có event_hash
    """
    q_docs = await db.execute(
        text(
            """
            SELECT id, file_name, file_hash, vc_hash_hex, doc_bundle_id
            FROM documents
            WHERE tenant_id = :tid AND doc_bundle_id = :bid
            ORDER BY id ASC
            """
        ),
        {"tid": tenant_id, "bid": bundle_id},
    )
    docs = [dict(zip(q_docs.keys(), r)) for r in q_docs.fetchall()]

    q_evts = await db.execute(
        text(
            """
            SELECT id, event_id, event_hash, event_type, batch_code, product_code
            FROM epcis_events
            WHERE tenant_id = :tid AND doc_bundle_id = :bid
            ORDER BY id ASC
            """
        ),
        {"tid": tenant_id, "bid": bundle_id},
    )
    events = [dict(zip(q_evts.keys(), r)) for r in q_evts.fetchall()]
    return docs, events


async def _ensure_all_vc_verified(
    db: AsyncSession, tenant_id: int, docs: List[Dict[str, Any]]
) -> Tuple[bool, List[str]]:
    """
    Kiểm tra tất cả tài liệu trong bundle đều có credential verified.
    Match theo credentials.hash_hex = documents.file_hash
    """
    if not docs:
        return False, ["no document in bundle"]

    file_hashes = [d["file_hash"] for d in docs if d.get("file_hash")]
    if not file_hashes:
        return False, ["documents missing file_hash"]

    rs = await db.execute(
        text(
            """
            SELECT hash_hex
            FROM credentials
            WHERE tenant_id=:tid AND status='verified' AND hash_hex = ANY(:hashes)
            """
        ),
        {"tid": tenant_id, "hashes": file_hashes},
    )
    verified = {r[0] for r in rs.fetchall()}
    missing = [h for h in file_hashes if h not in verified]
    return len(missing) == 0, missing


async def _check_anchor_duplicate(
    db: AsyncSession, tenant_id: int, bundle_id: str, network: str
) -> Optional[Dict[str, Any]]:
    rs = await db.execute(
        text(
            """
            SELECT id, tenant_id, bundle_id, network, batch_hash, tx_hash, block_number, status, created_at
            FROM blockchain_anchors
            WHERE tenant_id=:t AND bundle_id=:b AND network=:n
            LIMIT 1
            """
        ),
        {"t": tenant_id, "b": bundle_id, "n": network},
    )
    row = rs.first()
    return dict(zip(rs.keys(), row)) if row else None


async def _insert_anchor_record(
    db: AsyncSession,
    tenant_id: int,
    bundle_id: str,
    network: str,
    batch_hash: str,
    status: str,
    tx_hash: Optional[str] = None,
    block_number: Optional[int] = None,
) -> Dict[str, Any]:
    await db.execute(
        text(
            """
            INSERT INTO blockchain_anchors
                (tenant_id, bundle_id, network, batch_hash, tx_hash, block_number, status, created_at)
            VALUES
                (:t, :b, :n, :h, :tx, :blk, :st, NOW())
            ON CONFLICT (tenant_id, bundle_id, network) DO NOTHING
            """
        ),
        {
            "t": tenant_id,
            "b": bundle_id,
            "n": network,
            "h": batch_hash,
            "tx": tx_hash,
            "blk": block_number,
            "st": status,
        },
    )
    await db.commit()

    rs = await db.execute(
        text(
            """
            SELECT id, tenant_id, bundle_id, network, batch_hash, tx_hash, block_number, status, created_at
            FROM blockchain_anchors
            WHERE tenant_id=:t AND bundle_id=:b AND network=:n
            """
        ),
        {"t": tenant_id, "b": bundle_id, "n": network},
    )
    row = rs.first()
    return dict(zip(rs.keys(), row)) if row else {
        "tenant_id": tenant_id,
        "bundle_id": bundle_id,
        "network": network,
        "batch_hash": batch_hash,
        "status": status,
        "tx_hash": tx_hash,
        "block_number": block_number,
    }


# =========================
# POST /api/anchor/batch
# =========================
@router.post("/batch")
async def anchor_batch(
    body: dict,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=403, detail="Missing tenant_id")

    bundle_id = body.get("docBundleId")
    if not bundle_id:
        raise HTTPException(status_code=400, detail="docBundleId is required")

    cfg = await _get_default_chain(db, tenant_id)
    if not cfg:
        raise HTTPException(status_code=400, detail="No blockchain config for tenant")

    requested_network = (body.get("network") or cfg["network"] or "polygon").lower()
    networks = ["polygon", "fabric"] if requested_network == "both" else [requested_network]

    docs, events = await _load_bundle_data(db, tenant_id, bundle_id)
    if not docs:
        raise HTTPException(status_code=400, detail="No document found for bundle")
    if not events:
        raise HTTPException(status_code=400, detail="No EPCIS event found for bundle")

    ok, missing = await _ensure_all_vc_verified(db, tenant_id, docs)
    if not ok:
        raise HTTPException(
            status_code=400,
            detail=f"Bundle has unverified documents (missing verified credentials): {missing}",
        )

    leaves_docs = [d["vc_hash_hex"] for d in docs if d.get("vc_hash_hex")]
    leaves_evts = [e["event_hash"] for e in events if e.get("event_hash")]
    leaves = sorted(leaves_docs + leaves_evts)
    if not leaves:
        raise HTTPException(status_code=400, detail="No leaves to anchor")

    print(f"[DEBUG] Building Merkle root from {len(leaves)} leaves: {leaves}")
    batch_hash = _merkle_root_hex(leaves)

    private_key = body.get("private_key")
    results = []
    for net in networks:
        dup = await _check_anchor_duplicate(db, tenant_id, bundle_id, net)
        if dup:
            results.append({"network": net, "anchored": True, **dup})
            continue

        tx_hash, block_number, status = None, None, "prepared"

        try:
            if net == "polygon":
                # Placeholder for Polygon integration
                pass
            elif net == "fabric":
                # Placeholder for Fabric integration
                pass
        except Exception as chain_err:
            status = f"error:{chain_err}"

        rec = await _insert_anchor_record(
            db, tenant_id, bundle_id, net, batch_hash, status, tx_hash, block_number
        )
        results.append({"network": net, **rec})

    return {
        "ok": True,
        "bundle_id": bundle_id,
        "leaves_count": len(leaves),
        "batch_hash": batch_hash,
        "results": results,
    }


# =========================
# GET /api/anchor/status
# =========================
@router.get("/status")
async def anchor_status(
    bundle_id: str = Query(...),
    network: Optional[str] = Query(None, description="'polygon' | 'fabric'"),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=403, detail="Missing tenant_id")

    params = {"t": tenant_id, "b": bundle_id}
    q = """
        SELECT id, tenant_id, bundle_id, network, batch_hash, tx_hash, block_number, status, created_at
        FROM blockchain_anchors
        WHERE tenant_id=:t AND bundle_id=:b
    """
    if network:
        q += " AND network=:n"
        params["n"] = network
    q += " ORDER BY created_at DESC"

    rs = await db.execute(text(q), params)
    return {"ok": True, "bundle_id": bundle_id, "items": [dict(zip(rs.keys(), r)) for r in rs.fetchall()]}


# =========================
# GET /api/anchor/proof/{bundle_id}
# =========================
@router.get("/proof/{bundle_id}")
async def anchor_proof(
    bundle_id: str,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=403, detail="Missing tenant_id")

    docs, events = await _load_bundle_data(db, tenant_id, bundle_id)
    if not docs and not events:
        raise HTTPException(status_code=404, detail="Bundle not found or empty")

    leaves_docs = [d["vc_hash_hex"] for d in docs if d.get("vc_hash_hex")]
    leaves_evts = [e["event_hash"] for e in events if e.get("event_hash")]
    leaves = sorted(leaves_docs + leaves_evts)
    batch_hash = _merkle_root_hex(leaves) if leaves else None

    rs = await db.execute(
        text(
            """
            SELECT id, tenant_id, bundle_id, network, batch_hash, tx_hash, block_number, status, created_at
            FROM blockchain_anchors
            WHERE tenant_id=:t AND bundle_id=:b
            ORDER BY created_at DESC
            """
        ),
        {"t": tenant_id, "b": bundle_id},
    )
    anchors = [dict(zip(rs.keys(), r)) for r in rs.fetchall()]

    return {
        "ok": True,
        "bundle_id": bundle_id,
        "documents": [{"id": d["id"], "file_name": d["file_name"], "file_hash": d["file_hash"], "vc_hash_hex": d["vc_hash_hex"]} for d in docs],
        "epcis_events": [{"id": e["id"], "event_id": e["event_id"], "event_hash": e["event_hash"], "event_type": e["event_type"], "batch_code": e["batch_code"], "product_code": e["product_code"]} for e in events],
        "leaves": leaves,
        "merkle_root": batch_hash,
        "anchors": anchors,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
