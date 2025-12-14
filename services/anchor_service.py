import logging
from typing import Any, Dict

from app.services import dao_anchor
from app.blockchain.adapters.polygon_adapter import PolygonAdapter
from app.blockchain.utils import utc_now_iso

logger = logging.getLogger("anchor_service")


# ==============================================================
# 🔹 Publish batch lên blockchain (duy nhất 1 hàm public)
# ==============================================================
async def publish_batch_to_blockchain(
    db,
    tenant_id: int,
    bundle_id: str,
    root_hash: str
) -> Dict[str, Any]:
    """
    Đưa batch hash (Merkle root) của 1 lô hàng lên blockchain Polygon.
    - Tự động lấy config blockchain từ DB (configs_blockchain)
    - Kiểm tra trùng lặp (đã anchor chưa)
    - Gọi PolygonAdapter để gửi giao dịch
    - Ghi kết quả vào bảng blockchain_anchors
    """

    try:
        logger.info(f"[ANCHOR] Start publish for bundle={bundle_id}, tenant={tenant_id}")

        # ======================================================
        # 1️⃣ Kiểm tra xem bundle đã được anchor chưa
        # ======================================================
        existing = await dao_anchor.is_anchored(db, tenant_id, bundle_id, "polygon-amoy")
        if existing:
            logger.warning(f"[ANCHOR] Bundle {bundle_id} already anchored on chain")
            return {
                "ok": False,
                "status": "SKIPPED",
                "reason": "Already anchored",
                "existing_tx": existing.get("tx_hash"),
                "ts": utc_now_iso(),
            }

        # ======================================================
        # 2️⃣ Lấy cấu hình blockchain từ DB
        # ======================================================
        chain_cfg = await dao_anchor.get_chain_config(db, tenant_id)
        if not chain_cfg:
            logger.error("[ANCHOR] Blockchain configuration not found for tenant %s", tenant_id)
            return {"ok": False, "error": "Blockchain configuration not found"}

        cfg_json = chain_cfg.get("config_json") or {}
        network = chain_cfg.get("network", "polygon-amoy")
        rpc_url = chain_cfg.get("rpc_url")
        contract_address = chain_cfg.get("contract_address")
        private_key = cfg_json.get("private_key")

        if not rpc_url or not private_key or not contract_address:
            logger.error("[ANCHOR] Missing required blockchain config fields")
            return {"ok": False, "error": "Missing required blockchain configuration"}

        logger.info(f"[ANCHOR] Using RPC={rpc_url}, contract={contract_address}")

        # ======================================================
        # 3️⃣ Khởi tạo adapter kết nối blockchain
        # ======================================================
        adapter = PolygonAdapter(
            rpc_url=rpc_url,
            contract_address=contract_address,
            private_key=private_key,
            tenant_id=tenant_id,
            config_json=cfg_json,
        )

        # ======================================================
        # 4️⃣ Gọi adapter để publish root hash
        # ======================================================
        result = await adapter.anchor_batch(
            bundle_id=bundle_id,
            batch_hash=root_hash,
            meta={"bundle_id": bundle_id, "tenant_id": tenant_id},
        )

        # ======================================================
        # 5️⃣ Ghi kết quả vào DB nếu thành công
        # ======================================================
        if result.get("status") == "CONFIRMED":
            payload = {
                "tenant_id": tenant_id,
                "anchor_type": "bundle",
                "ref": bundle_id,
                "tx_hash": result["tx_hash"],
                "network": result.get("network", network),
                "meta": {
                    "bundle_id": bundle_id,
                    "method": "anchor_batch",
                    "confirmed_at": result.get("ts"),
                },
                "batch_hash": root_hash,
                "block_number": result.get("block_number", 0),
                "status": "CONFIRMED",
            }

            await dao_anchor.insert_anchor(db, payload)
            logger.info(
                f"[ANCHOR] ✅ Confirmed on-chain: {bundle_id} "
                f"tx={result['tx_hash']} block={result.get('block_number')}"
            )
            return {"ok": True, **result}

        else:
            logger.error(f"[ANCHOR] ❌ Failed to publish bundle={bundle_id}: {result}")
            return {"ok": False, "error": result.get("error", "Unknown error"), "detail": result}

    except Exception as e:
        logger.exception(f"[ANCHOR] Unexpected error: {e}")
        return {"ok": False, "error": str(e), "status": "FAILED", "ts": utc_now_iso()}
