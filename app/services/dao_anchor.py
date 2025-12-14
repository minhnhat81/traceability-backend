from typing import List, Dict, Any, Optional
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# ==============================================================
# 🔹 Lấy cấu hình blockchain theo tenant
# ==============================================================
async def get_chain_config(db: AsyncSession, tenant_id: int) -> Optional[Dict[str, Any]]:
    sql = """
    SELECT 
        id,
        tenant_id,
        chain_name AS network,
        rpc_url,
        contract_address,
        config_json
    FROM configs_blockchain
    WHERE tenant_id = :t
    ORDER BY id DESC
    LIMIT 1
    """
    rs = await db.execute(text(sql), {"t": tenant_id})
    row = rs.fetchone()
    return dict(zip(rs.keys(), row)) if row else None


# ==============================================================
# 🔹 Lấy EPCIS events theo bundle
# ==============================================================
async def get_epcis_events(db: AsyncSession, tenant_id: int, bundle_id: str):
    sql = """
    SELECT id, event_hash, event_id, biz_step, doc_bundle_id
    FROM epcis_events 
    WHERE tenant_id = :tid 
      AND doc_bundle_id = :bid
    ORDER BY created_at DESC
    """
    rs = await db.execute(text(sql), {"tid": tenant_id, "bid": bundle_id})
    rows = rs.fetchall()
    return [dict(zip(rs.keys(), r)) for r in rows] if rows else []


# ==============================================================
# 🔹 Kiểm tra xem bundle đã được anchor chưa
# ==============================================================
async def is_anchored(
    db: AsyncSession,
    tenant_id: int,
    bundle_id: str,
    network: str
):
    """
    Dùng bảng blockchain_anchors và cột ref = bundle_id
    """
    sql = """
    SELECT 
        id,
        tenant_id,
        anchor_type,
        ref,
        tx_hash,
        network,
        meta,
        batch_hash,
        block_number,
        status,
        ipfs_cid,
        created_at,
        updated_at
    FROM blockchain_anchors
    WHERE tenant_id = :t
      AND ref = :ref
      AND network = :n
    ORDER BY created_at DESC
    LIMIT 1
    """

    rs = await db.execute(
        text(sql),
        {"t": tenant_id, "ref": bundle_id, "n": network},
    )
    row = rs.fetchone()
    return dict(zip(rs.keys(), row)) if row else None


# ==============================================================
# 🔹 Lưu anchor mới vào blockchain_anchors
# ==============================================================
async def insert_anchor(db: AsyncSession, payload: Dict[str, Any]):
    """
    Mapping chuẩn với bảng blockchain_anchors:
    - ref        = bundle_id hoặc batch_code
    - batch_hash = Merkle root (root_hash)
    - ipfs_cid   = CID file DPP trên IPFS
    """

    sql = """
    INSERT INTO blockchain_anchors(
        tenant_id,
        anchor_type,
        ref,
        tx_hash,
        network,
        meta,
        batch_hash,
        block_number,
        status,
        ipfs_cid,
        created_at,
        updated_at
    ) VALUES (
        :tenant_id,
        COALESCE(:anchor_type, 'bundle'),
        :ref,
        :tx_hash,
        :network,
        to_jsonb(:meta::json),
        :batch_hash,
        :block_number,
        :status,
        :ipfs_cid,
        NOW(),
        NOW()
    )
    """

    await db.execute(
        text(sql),
        {
            "tenant_id": payload["tenant_id"],
            "anchor_type": payload.get("anchor_type", "bundle"),
            "ref": payload["ref"],
            "tx_hash": payload.get("tx_hash"),
            "network": payload["network"],
            "meta": payload.get("meta", {}),
            "batch_hash": payload.get("batch_hash"),
            "block_number": payload.get("block_number"),
            "status": payload.get("status", "CONFIRMED"),
            "ipfs_cid": payload.get("ipfs_cid"),
        },
    )

    await db.commit()
