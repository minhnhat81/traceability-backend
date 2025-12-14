from typing import Any, Dict, Optional, Tuple, Union
import logging
import os

from app.blockchain.base import BlockchainAdapter
from app.blockchain.utils import utc_now_iso, short_tx_hash

logger = logging.getLogger("polygon_adapter")


class PolygonAdapter(BlockchainAdapter):
    """
    Adapter kết nối mạng Polygon (hoặc EVM tương thích).
    v3: tự động gắn ABI ProofRegistry mặc định nếu không có, 
    hỗ trợ mock mode, auto gas (EIP-1559), chainId check & auto-switch RPC.
    """

    def __init__(
        self,
        rpc_url: str,
        contract_address: Optional[str] = None,
        private_key: Optional[str] = None,
        tenant_id: int = 1,
        config_json: Optional[Dict[str, Any]] = None,
    ):
        try:
            from web3 import Web3
        except ImportError:
            Web3 = None

        self.rpc_url = rpc_url
        self.contract_address = contract_address
        self.private_key = (private_key or os.getenv("POLYGON_PRIVATE_KEY")) or None
        self.tenant_id = tenant_id
        self.Web3 = Web3
        self.web3 = Web3(Web3.HTTPProvider(rpc_url)) if Web3 else None
        self.config_json = config_json or {}

        # 🔹 Gắn ABI mặc định nếu chưa có trong config_json
        default_abi = [
            {
                "inputs": [
                    {"internalType": "string", "name": "ref", "type": "string"},
                    {"internalType": "bytes32", "name": "rootHash", "type": "bytes32"},
                ],
                "name": "anchor",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function",
            },
            {
                "inputs": [{"internalType": "string", "name": "ref", "type": "string"}],
                "name": "get",
                "outputs": [{"internalType": "bytes32", "name": "", "type": "bytes32"}],
                "stateMutability": "view",
                "type": "function",
            },
            {
                "anonymous": False,
                "inputs": [
                    {"indexed": False, "internalType": "string", "name": "ref", "type": "string"},
                    {"indexed": False, "internalType": "bytes32", "name": "rootHash", "type": "bytes32"},
                    {"indexed": True, "internalType": "address", "name": "sender", "type": "address"},
                ],
                "name": "Anchored",
                "type": "event",
            },
        ]

        self.abi = self.config_json.get("abi") or default_abi

    # ==========================================================
    # INTERNAL HELPERS
    # ==========================================================
    def _cfg(self, key: str, default: Any) -> Any:
        return (self.config_json or {}).get(key, default)

    @staticmethod
    def _coerce_chain_id(raw: Union[int, str, list, tuple], fallback: int) -> int:
        try:
            if isinstance(raw, (list, tuple)) and len(raw) > 0:
                return int(raw[0])
            return int(raw)
        except Exception:
            return int(fallback)

    def _maybe_switch_rpc_for_chain(self, expected_chain_id: int) -> None:
        if not self.web3:
            return
        try:
            current_chain_id = int(self.web3.eth.chain_id)
        except Exception as e:
            logger.warning(f"[PolygonAdapter] Cannot fetch chain_id from RPC {self.rpc_url}: {e}")
            return
        if current_chain_id == expected_chain_id:
            return
        target_rpc = None
        if expected_chain_id == 137:
            target_rpc = "https://polygon-rpc.com"
        elif expected_chain_id == 80002:
            target_rpc = "https://rpc-amoy.polygon.technology"
        if target_rpc:
            logger.warning(
                f"[PolygonAdapter] RPC chainId mismatch (RPC={current_chain_id}, expected={expected_chain_id}). "
                f"Auto-switching RPC to {target_rpc}"
            )
            self.rpc_url = target_rpc
            self.web3 = self.Web3(self.Web3.HTTPProvider(self.rpc_url))

    def _get_fees_eip1559(self) -> Tuple[int, int]:
        """Tính (maxFeePerGas, maxPriorityFeePerGas) theo Wei."""
        assert self.web3 is not None

        def _to_wei_maybe_gwei(v: int) -> int:
            v_int = int(v)
            return v_int if v_int >= 1_000_000_000 else self.web3.to_wei(v_int, "gwei")

        min_tip_gwei = int(self._cfg("min_priority_fee_gwei", 25))
        min_tip_wei = self.web3.to_wei(min_tip_gwei, "gwei")

        cfg_max_fee = self._cfg("max_fee_gwei", None)
        cfg_tip = self._cfg("priority_fee_gwei", None)
        if cfg_max_fee is not None and cfg_tip is not None:
            tip_wei = _to_wei_maybe_gwei(cfg_tip)
            max_fee_wei = _to_wei_maybe_gwei(cfg_max_fee)
            if tip_wei < min_tip_wei:
                tip_wei = min_tip_wei
            if max_fee_wei < tip_wei * 2:
                max_fee_wei = tip_wei * 2
            logger.info(f"[PolygonAdapter] Using config fees maxFee={max_fee_wei} tip={tip_wei}")
            return max_fee_wei, tip_wei

        try:
            fee_hist = self.web3.eth.fee_history(3, "latest", [10, 30, 50])
            base = int(fee_hist["baseFeePerGas"][-1])
            rewards = [int(x[1]) for x in fee_hist["reward"] if x and len(x) > 1]
            tip = int(sorted(rewards)[len(rewards) // 2]) if rewards else min_tip_wei
            if tip < min_tip_wei:
                tip = min_tip_wei
            max_fee = max(base + tip * 2, tip * 2)
            logger.info(f"[PolygonAdapter] Using estimated fees base={base} maxFee={max_fee} tip={tip}")
            return max_fee, tip
        except Exception as e:
            max_fee = self.web3.to_wei(50, "gwei")
            tip = min_tip_wei
            logger.warning(f"[PolygonAdapter] fee_history failed ({e}); fallback maxFee={max_fee} tip={tip}")
            return max_fee, tip

    def _estimate_and_bound_gas(self, tx: Dict[str, Any], hard_cap: int) -> int:
        assert self.web3 is not None
        try:
            est = int(self.web3.eth.estimate_gas(tx))
            est_buffer = int(est * 1.3)
            final_gas = min(est_buffer, int(hard_cap))
            logger.info(f"[PolygonAdapter] estimate_gas={est}, buffered={est_buffer}, cap={hard_cap}")
            return final_gas
        except Exception as e:
            logger.warning(f"[PolygonAdapter] estimate_gas failed ({e}), use hard_cap={hard_cap}")
            return int(hard_cap)

    def _is_mock(self) -> bool:
        return str(self._cfg("mode", "real")).lower() == "mock"

    # ==========================================================
    # ANCHOR BATCH
    # ==========================================================
    async def anchor_batch(self, bundle_id: str, batch_hash: str, meta: Dict[str, Any]) -> Dict[str, Any]:
        """Gửi Merkle root lên Polygon chain hoặc mô phỏng (mock mode)."""
        try:
            if self._is_mock() or (not self.Web3) or (not self.private_key) or (not self.contract_address):
                tx_hash = short_tx_hash(bundle_id, batch_hash)
                logger.info(f"[MOCK] Anchored {bundle_id} on Polygon tx={tx_hash}")
                return {
                    "network": "polygon-amoy",
                    "tx_hash": tx_hash,
                    "block_number": int(batch_hash[:8], 16) % 5_000_000,
                    "status": "CONFIRMED",
                    "ts": utc_now_iso(),
                }

            acct = self.web3.eth.account.from_key(self.private_key)
            expected_chain_id = self._coerce_chain_id(self._cfg("chain_id", 80002), 80002)
            self._maybe_switch_rpc_for_chain(expected_chain_id)
            chain_id = int(self.web3.eth.chain_id)
            max_fee_wei, tip_wei = self._get_fees_eip1559()
            nonce = self.web3.eth.get_transaction_count(acct.address)
            gas_cap = int(self._cfg("gas_limit", 5_000_000))

            contract = self.web3.eth.contract(address=self.contract_address, abi=self.abi)

            # ✅ Encode batch_hash thành bytes32 chuẩn
            import hashlib
            if isinstance(batch_hash, str):
                clean = batch_hash.strip().lower()
                if clean.startswith("0x") and len(clean) == 66:
                    hash_bytes32 = self.web3.to_bytes(hexstr=clean)
                else:
                    hash_bytes32 = hashlib.sha256(clean.encode()).digest()
            elif isinstance(batch_hash, (bytes, bytearray)):
                hash_bytes32 = bytes(batch_hash)
            else:
                hash_bytes32 = hashlib.sha256(str(batch_hash).encode()).digest()

            if len(hash_bytes32) != 32:
                raise ValueError(f"Invalid batch_hash length: {len(hash_bytes32)} (expected 32)")

            # 🔍 Preflight simulation
            try:
                contract.functions.anchor(bundle_id, hash_bytes32).call({"from": acct.address})
                logger.info(f"[Preflight] anchor({bundle_id}) simulation ✅ passed.")
            except Exception as pre:
                reason = str(pre)
                if "revert reason:" in reason:
                    reason = reason.split("revert reason:")[-1].strip()
                elif "execution reverted" in reason:
                    reason = reason.split("execution reverted")[-1].strip()
                logger.error(f"[Preflight] ❌ anchor({bundle_id}) simulation reverted! Reason: {reason}")
                return {
                    "network": "polygon-amoy" if chain_id == 80002 else "polygon",
                    "status": "SIMULATION_REVERTED",
                    "reason": reason,
                    "tx_hash": None,
                    "ts": utc_now_iso(),
                }

            # 🧱 Build transaction
            built = contract.functions.anchor(bundle_id, hash_bytes32).build_transaction(
                {
                    "from": acct.address,
                    "nonce": nonce,
                    "chainId": chain_id,
                    "maxFeePerGas": max_fee_wei,
                    "maxPriorityFeePerGas": tip_wei,
                    "value": 0,
                }
            )
            built["gas"] = self._estimate_and_bound_gas(built, gas_cap)
            signed = acct.sign_transaction(built)
            tx_hash = self.web3.eth.send_raw_transaction(signed.rawTransaction).hex()
            receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash)

            # 🩺 Check status
            if int(receipt.status) == 0:
                revert_reason = None
                try:
                    contract.functions.anchor(bundle_id, hash_bytes32).call({"from": acct.address})
                except Exception as call_err:
                    msg = str(call_err)
                    if "revert reason:" in msg:
                        revert_reason = msg.split("revert reason:")[-1].strip()
                    elif "execution reverted" in msg:
                        revert_reason = msg.split("execution reverted")[-1].strip()
                    else:
                        revert_reason = msg
                logger.error(
                    f"[PolygonAdapter] ❌ Transaction reverted on-chain! "
                    f"bundle={bundle_id} reason={revert_reason or 'unknown'} tx={tx_hash}"
                )
                return {
                    "network": "polygon-amoy" if chain_id == 80002 else "polygon",
                    "tx_hash": tx_hash,
                    "block_number": receipt.blockNumber,
                    "status": "REVERTED",
                    "error": revert_reason or "Transaction failed on-chain",
                    "ts": utc_now_iso(),
                }

            logger.info(f"[PolygonAdapter] Anchored {bundle_id} OK (block={receipt.blockNumber})")
            return {
                "network": "polygon-amoy" if chain_id == 80002 else "polygon",
                "tx_hash": tx_hash,
                "block_number": receipt.blockNumber,
                "status": "CONFIRMED",
                "ts": utc_now_iso(),
            }

        except Exception as e:
            logger.exception(f"anchor_batch failed: {e}")
            return {"network": "polygon", "status": "FAILED", "error": str(e)}
    # ==========================================================
    # TEST CONNECTION (NEW)
    # ==========================================================
    async def test_connection(self) -> Dict[str, Any]:
        """
        Kiểm tra RPC + chainId + contract.
        Không phụ thuộc manager → gọi trực tiếp được.
        """
        try:
            if not self.Web3:
                return {"ok": False, "network": "polygon", "error": "Web3 not installed"}

            web3 = self.web3
            if not web3:
                return {"ok": False, "network": "polygon", "error": "Invalid RPC or no Web3 instance"}

            # 🔍 Test RPC reachable
            chain_id = int(web3.eth.chain_id)
            latest_block = int(web3.eth.block_number)

            # 🔍 Nếu contract address có thì test luôn khả năng gọi hàm "get"
            contract_ok = False
            contract_error = None

            if self.contract_address:
                try:
                    contract = web3.eth.contract(address=self.contract_address, abi=self.abi)
                    # Gọi thử hàm view không phí gas
                    _ = contract.functions.get("ping").call()
                    contract_ok = True
                except Exception as e:
                    contract_error = str(e)

            return {
                "ok": True,
                "network": "polygon",
                "rpc_url": self.rpc_url,
                "chain_id": chain_id,
                "latest_block": latest_block,
                "contract_address": self.contract_address,
                "contract_ok": contract_ok,
                "contract_error": contract_error,
                "ts": utc_now_iso(),
            }

        except Exception as e:
            return {
                "ok": False,
                "network": "polygon",
                "error": str(e),
                "ts": utc_now_iso(),
            }

    # ==========================================================
    # DEPLOY CONTRACT
    # ==========================================================
    async def deploy_contract(self, db=None, tenant_id: int = 1, chain_id: int = 80002) -> Dict[str, Any]:
        """Triển khai smart contract ProofRegistry."""
        if not self.Web3:
            return {"ok": False, "error": "Web3 not installed"}
        if self._is_mock():
            pseudo_addr = "0x" + short_tx_hash("DEPLOY", "MOCK")[2:].ljust(40, "0")[:40]
            return {
                "ok": True,
                "tx_hash": "0x" + "MOCK".ljust(64, "0"),
                "contract_address": pseudo_addr,
                "chain_id": chain_id,
                "network": "polygon-amoy" if int(chain_id) == 80002 else "polygon",
                "ts": utc_now_iso(),
                "mock": True,
            }
        if not self.private_key:
            return {"ok": False, "error": "Private key not configured"}

        try:
            from solcx import compile_source, install_solc, set_solc_version
        except ImportError:
            return {"ok": False, "error": "python-solcx not installed"}

        try:
            cfg = self.config_json
            expected_chain_id = self._coerce_chain_id(cfg.get("chain_id", chain_id), chain_id)
            self._maybe_switch_rpc_for_chain(expected_chain_id)
            rpc_chain_id = int(self.web3.eth.chain_id)
            gas_limit = int(cfg.get("gas_limit", 8_000_000))
            if gas_limit < 1_000_000:
                gas_limit = 8_000_000
            max_fee_wei, tip_wei = self._get_fees_eip1559()
            acct = self.web3.eth.account.from_key(self.private_key)

            source_code = """
            // SPDX-License-Identifier: MIT
            pragma solidity ^0.8.20;

            contract ProofRegistry {
                event Anchored(string ref, bytes32 rootHash, address indexed sender);
                mapping(string => bytes32) public proofs;

                function anchor(string calldata ref, bytes32 rootHash) external {
                    proofs[ref] = rootHash;
                    emit Anchored(ref, rootHash, msg.sender);
                }

                function get(string calldata ref) external view returns (bytes32) {
                    return proofs[ref];
                }
            }
            """
            install_solc("0.8.20")
            set_solc_version("0.8.20")
            compiled = compile_source(source_code)
            _, interface = compiled.popitem()
            bytecode = interface["bin"]
            abi = interface["abi"]

            ProofRegistry = self.web3.eth.contract(abi=abi, bytecode=bytecode)
            nonce = self.web3.eth.get_transaction_count(acct.address)
            tx = ProofRegistry.constructor().build_transaction(
                {
                    "from": acct.address,
                    "nonce": nonce,
                    "maxFeePerGas": max_fee_wei,
                    "maxPriorityFeePerGas": tip_wei,
                    "chainId": rpc_chain_id,
                    "value": 0,
                }
            )

            try:
                est = int(self.web3.eth.estimate_gas(tx))
                tx["gas"] = min(int(est * 1.3), gas_limit)
                logger.info(f"[PolygonAdapter] Gas estimate={est}, final gas={tx['gas']}")
            except Exception as eg:
                logger.warning(f"[PolygonAdapter] estimate_gas (deploy) failed: {eg}; fallback gas={gas_limit}")
                tx["gas"] = gas_limit

            logger.info(f"[PolygonAdapter] Fees used (deploy): maxFee={max_fee_wei} tip={tip_wei}")
            signed = acct.sign_transaction(tx)
            tx_hash = self.web3.eth.send_raw_transaction(signed.rawTransaction)
            logger.info(f"[PolygonAdapter] Deploying contract... TX={tx_hash.hex()}")
            receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash)
            contract_address = receipt.contractAddress
            logger.info(f"[PolygonAdapter] Contract deployed at {contract_address} (block={receipt.blockNumber})")

            if db:
                from sqlalchemy import text
                await db.execute(
                    text(
                        """
                        INSERT INTO configs_blockchain
                            (tenant_id, chain_name, rpc_url, contract_address, network, created_at, updated_at)
                        VALUES
                            (:t, 'Polygon Amoy', :r, :a, :n, NOW(), NOW())
                        """
                    ),
                    {
                        "t": tenant_id,
                        "r": self.rpc_url,
                        "a": contract_address,
                        "n": "polygon-amoy" if rpc_chain_id == 80002 else "polygon",
                    },
                )
                await db.commit()

            self.abi = abi
            return {
                "ok": True,
                "tx_hash": tx_hash.hex(),
                "contract_address": contract_address,
                "chain_id": rpc_chain_id,
                "network": "polygon-amoy" if rpc_chain_id == 80002 else "polygon",
                "ts": utc_now_iso(),
            }

        except Exception as e:
            logger.exception(f"Deploy contract failed: {e}")
            return {"ok": False, "error": str(e)}
