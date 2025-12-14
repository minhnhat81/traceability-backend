from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from web3 import Web3
import os
import logging
from app.services.polygon_adapter_v2 import PolygonAdapterV2
from app.services.dao_anchor import DaoAnchor

router = APIRouter()
logger = logging.getLogger("blockchain_verify")

class VerifyRequest(BaseModel):
    batch_code: str

# Web3 config
RPC_URL = os.getenv("POLYGON_RPC_URL", "https://rpc-amoy.polygon.technology")
web3 = Web3(Web3.HTTPProvider(RPC_URL))

@router.post("/blockchain/verify")
async def verify_on_chain(req: VerifyRequest):
    batch_code = req.batch_code.strip()
    if not batch_code:
        raise HTTPException(status_code=400, detail="Missing batch_code")

    logger.info(f"🔍 Verifying on-chain transaction for batch {batch_code}...")

    # Fetch batch proof data (saved earlier)
    dao = DaoAnchor()
    proof = dao.get_proof_by_batch(batch_code)
    if not proof or not proof.tx_hash:
        raise HTTPException(status_code=404, detail="No transaction found for this batch")

    tx_hash = proof.tx_hash
    logger.info(f"Checking tx hash: {tx_hash}")

    try:
        tx_receipt = web3.eth.get_transaction_receipt(tx_hash)
    except Exception as e:
        logger.error(f"❌ Cannot get tx receipt: {e}")
        raise HTTPException(status_code=400, detail=f"Cannot verify transaction: {e}")

    if tx_receipt and tx_receipt.status == 1:
        block_number = tx_receipt.blockNumber
        dao.update_status(batch_code, "CONFIRMED", block_number)
        logger.info(f"✅ Batch {batch_code} confirmed on block {block_number}")
        return {
            "batch_code": batch_code,
            "status": "CONFIRMED",
            "block_number": block_number,
            "tx_hash": tx_hash,
        }

    else:
        dao.update_status(batch_code, "FAILED")
        logger.warning(f"⚠️ Batch {batch_code} transaction failed on-chain")
        return {
            "batch_code": batch_code,
            "status": "FAILED",
            "tx_hash": tx_hash,
        }
