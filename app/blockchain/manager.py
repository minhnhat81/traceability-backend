from typing import Dict, Any
from app.services import dao_anchor as dao
from app.blockchain.polygon_adapter import PolygonAdapter
from app.blockchain.fabric_adapter import FabricAdapter
from app.blockchain.utils import merkle_root_hex, utc_now_iso
import logging, json

logger = logging.getLogger("blockchain_manager")


class BlockchainManager:
    """
    Lớp điều phối logic anchor dữ liệu bundle lên các mạng blockchain
    (Polygon / Fabric), đọc cấu hình từ bảng configs_blockchain.
    """

    def __init__(self, polygon_adapter=None, fabric_adapter=None):
        self.polygon = polygon_adapter or PolygonAdapter(
            rpc_url="https://polygon-rpc.com",
            contract_address=None,
            private_key=None,
        )
        self.fabric = fabric_adapter or FabricAdapter(
            gateway_url="http://localhost:7050",
            channel="traceability",
            chaincode="trace_cc",
        )

    # ============================================================
    async def _get_adapter(self, db, tenant_id: int, network: str):
        """Lấy adapter tương ứng với network (Polygon hoặc Fabric)."""
        cfg = await dao.get_chain_config(db, tenant_id)
        if not cfg:
            raise ValueError("Blockchain config not found")
        cfg_json = cfg.get("config_json") or {}
        if isinstance(cfg_json, str):
            try:
                cfg_json = json.loads(cfg_json)
            except Exception:
                cfg_json = {}

        if network.lower() == "polygon":
            return PolygonAdapter(
                rpc_url=cfg.get("rpc_url"),
                contract_address=cfg.get("contract_address"),
                private_key=cfg_json.get("private_key"),
                tenant_id=tenant_id,
                config_json=cfg_json,
            )
        elif network.lower() == "fabric":
            return FabricAdapter(
                gateway_url=cfg_json.get("gateway_url"),
                channel=cfg_json.get("channel_name") or cfg_json.get("channel") or "traceability",
                chaincode=cfg_json.get("chaincode_name") or cfg_json.get("chaincode") or "trace_cc",
                tenant_id=tenant_id,
            )
        else:
            raise ValueError(f"Unsupported network: {network}")

    # ============================================================
        # ============================================================
    async def test_connection(self, network: str, db=None, tenant_id: int = 1):
        """Kiểm tra kết nối tới Polygon hoặc Fabric."""
        try:
            adapter = await self._get_adapter(db, tenant_id, network)

            if not hasattr(adapter, "test_connection"):
                return {
                    "ok": False,
                    "network": network,
                    "status": "FAILED",
                    "error": f"{adapter.__class__.__name__} has no test_connection()"
                }

            return await adapter.test_connection()

        except Exception as e:
            logger.exception(f"[TEST] Blockchain connection failed: {e}")
            return {"network": network, "status": "FAILED", "error": str(e)}


    # ============================================================
    async def deploy_contract(self, network: str, db=None, tenant_id: int = 1) -> Dict[str, Any]:
        """Triển khai smart contract hoặc chaincode."""
        try:
            adapter = await self._get_adapter(db, tenant_id, network)
            return await adapter.deploy_contract(db=db, tenant_id=tenant_id)
        except Exception as e:
            logger.exception(f"[DEPLOY] Blockchain deploy failed: {e}")
            return {"network": network, "status": "FAILED", "error": str(e)}

    # ============================================================
    async def anchor_bundle(self, db, tenant_id: int, bundle_id: str, network: str, meta: Dict[str, Any]):
        logger.info(f"[ANCHOR] Start bundle={bundle_id}, network={network}")
        docs = await dao.get_docs_verified(db, tenant_id, bundle_id)
        evts = await dao.get_epcis_events(db, tenant_id, bundle_id)
        if not docs or not evts:
            raise ValueError("Bundle incomplete or no verified documents/events found.")

        leaves = sorted([*(d["vc_hash_hex"] for d in docs), *(e["event_hash"] for e in evts)])
        batch_hash = merkle_root_hex(leaves)
        logger.debug(f"[ANCHOR] Merkle root={batch_hash}")

        dup = await dao.is_anchored(db, tenant_id, bundle_id, network)
        if dup:
            logger.info(f"[ANCHOR] Skipped (already anchored): {bundle_id}")
            return dup

        # 🔹 Chọn adapter tương ứng
        adapter = await self._get_adapter(db, tenant_id, network)
        res = await adapter.anchor_batch(bundle_id, batch_hash, meta)

        await dao.insert_anchor(
            db,
            {
                "tenant_id": tenant_id,
                "ref": bundle_id,
                "network": network,
                "batch_hash": batch_hash,
                "tx_hash": res.get("tx_hash"),
                "block_number": res.get("block_number"),
                "status": res.get("status"),
                "meta": json.dumps(meta),
            },
        )

        result = {
            "bundle_id": bundle_id,
            "network": network,
            "batch_hash": batch_hash,
            "tx_hash": res.get("tx_hash"),
            "block_number": res.get("block_number"),
            "status": res.get("status"),
        }
        logger.info(f"[ANCHOR] Done: {result}")
        return result
