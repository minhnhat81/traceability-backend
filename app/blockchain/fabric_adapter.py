# app/blockchain/fabric_adapter.py
from typing import Any, Dict
import logging, httpx, asyncio, os
from sqlalchemy import text
from app.blockchain.base import BlockchainAdapter
from app.blockchain.utils import utc_now_iso, short_tx_hash

logger = logging.getLogger("fabric_adapter")


class FabricAdapter(BlockchainAdapter):
    """
    Adapter gửi hash EPCIS lên mạng Hyperledger Fabric.
    Hỗ trợ test + deploy chaincode thật qua REST Gateway.
    """

    def __init__(self, gateway_url: str, channel: str, chaincode: str, tenant_id: int = 1):
        self.gateway_url = gateway_url.rstrip("/") if gateway_url else None
        self.channel = channel
        self.chaincode = chaincode
        self.tenant_id = tenant_id

    # ============================================================
    async def test_connection(self) -> Dict[str, Any]:
        """
        Kiểm tra gateway Fabric có phản hồi hay không.
        """
        try:
            if not self.gateway_url:
                return {"network": "fabric", "status": "FAILED", "error": "Missing gateway_url"}

            async with httpx.AsyncClient(timeout=5) as client:
                r = await client.get(f"{self.gateway_url}/healthz")
                if r.status_code == 200:
                    return {
                        "network": "fabric",
                        "channel": self.channel,
                        "chaincode": self.chaincode,
                        "gateway_url": self.gateway_url,
                        "status": "CONNECTED",
                        "ts": utc_now_iso(),
                    }
                return {"network": "fabric", "status": "FAILED", "error": f"HTTP {r.status_code}"}
        except Exception as e:
            logger.exception(f"Fabric test failed: {e}")
            return {"network": "fabric", "status": "FAILED", "error": str(e)}

    # ============================================================
    async def deploy_contract(self, db=None, tenant_id: int = 1) -> Dict[str, Any]:
        """
        Deploy chaincode thật qua Fabric Gateway REST API:
        1. /chaincode/install
        2. /chaincode/approve
        3. /chaincode/commit
        """
        try:
            async with httpx.AsyncClient(timeout=60) as client:
                # === 1️⃣ Install chaincode ===
                chaincode_name = self.chaincode
                version = os.getenv("FABRIC_CC_VERSION", "1.0")
                package_path = os.getenv("FABRIC_CC_PACKAGE", f"./chaincode/{chaincode_name}.tar.gz")

                if not os.path.exists(package_path):
                    raise ValueError(f"Chaincode package not found: {package_path}")

                logger.info(f"[Fabric] Installing chaincode {chaincode_name} ({package_path})")

                with open(package_path, "rb") as f:
                    files = {"file": (f"{chaincode_name}.tar.gz", f, "application/gzip")}
                    install_resp = await client.post(f"{self.gateway_url}/chaincode/install", files=files)

                if install_resp.status_code != 200:
                    raise Exception(f"Install failed: {install_resp.text}")
                install_data = install_resp.json()
                package_id = install_data.get("packageId")

                logger.info(f"[Fabric] Installed package_id={package_id}")

                # === 2️⃣ Approve chaincode ===
                approve_body = {
                    "channel": self.channel,
                    "chaincode": chaincode_name,
                    "packageId": package_id,
                    "version": version,
                    "sequence": int(os.getenv("FABRIC_CC_SEQUENCE", 1)),
                    "endorsementPolicy": "AND('Org1.member','Org2.member')",
                }
                approve_resp = await client.post(f"{self.gateway_url}/chaincode/approve", json=approve_body)
                if approve_resp.status_code != 200:
                    raise Exception(f"Approve failed: {approve_resp.text}")
                logger.info(f"[Fabric] Chaincode approved")

                # === 3️⃣ Commit chaincode ===
                commit_body = {
                    "channel": self.channel,
                    "chaincode": chaincode_name,
                    "version": version,
                    "sequence": approve_body["sequence"],
                }
                commit_resp = await client.post(f"{self.gateway_url}/chaincode/commit", json=commit_body)
                if commit_resp.status_code != 200:
                    raise Exception(f"Commit failed: {commit_resp.text}")
                commit_data = commit_resp.json()
                tx_id = commit_data.get("txId", "unknown_tx")
                logger.info(f"[Fabric] Chaincode committed tx={tx_id}")

                # === 4️⃣ Save config ===
                if db:
                    await db.execute(
                        text(
                            """
                            INSERT INTO configs_blockchain 
                                (tenant_id, chain_name, rpc_url, contract_address, network, abi_id, is_default, created_at, updated_at)
                            VALUES 
                                (:t, :n, :r, :a, :nw, :abi, true, NOW(), NOW())
                            """
                        ),
                        {
                            "t": tenant_id,
                            "n": "Fabric",
                            "r": self.gateway_url,
                            "a": chaincode_name,
                            "nw": "fabric-prod",
                            "abi": 1,
                        },
                    )
                    await db.commit()

                return {
                    "ok": True,
                    "network": "fabric",
                    "chaincode": chaincode_name,
                    "channel": self.channel,
                    "package_id": package_id,
                    "tx_id": tx_id,
                    "status": "DEPLOYED",
                    "ts": utc_now_iso(),
                }

        except Exception as e:
            logger.exception(f"Fabric deploy failed: {e}")
            return {"network": "fabric", "status": "FAILED", "error": str(e)}

    # ============================================================
    async def anchor_batch(self, bundle_id: str, batch_hash: str, meta: Dict[str, Any]) -> Dict[str, Any]:
        """
        Ghi hash của bundle lên Fabric.
        Nếu gateway_url không có thật -> chế độ mô phỏng.
        """
        try:
            if not self.gateway_url:
                # mock mode
                tx_hash = short_tx_hash(bundle_id, batch_hash)
                logger.info(f"[MOCK] Anchored {bundle_id} on Fabric tx={tx_hash}")
                return {
                    "network": "fabric",
                    "tx_hash": tx_hash,
                    "block_number": 0,
                    "status": "CONFIRMED",
                    "ts": utc_now_iso(),
                }

            async with httpx.AsyncClient(timeout=30) as client:
                payload = {
                    "fcn": "AnchorProof",
                    "args": [bundle_id, batch_hash],
                    "channel": self.channel,
                    "chaincode": self.chaincode,
                }
                resp = await client.post(f"{self.gateway_url}/invoke", json=payload)
                if resp.status_code != 200:
                    raise Exception(f"Invoke failed: {resp.text}")
                data = resp.json()
                tx_id = data.get("txId", short_tx_hash(bundle_id, batch_hash))

                return {
                    "network": "fabric",
                    "tx_hash": tx_id,
                    "block_number": 1,
                    "status": "CONFIRMED",
                    "ts": utc_now_iso(),
                }

        except Exception as e:
            logger.exception(f"Fabric anchor failed: {e}")
            return {"network": "fabric", "status": "FAILED", "error": str(e)}
