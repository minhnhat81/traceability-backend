from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.core.security import verify_jwt

router = APIRouter(prefix="/api/ledger", tags=["ledger"])

# =============================
# 🧱 Fabric Ledger Log
# =============================
@router.get("/fabric")
def fabric(limit: int = 200, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    rows = db.execute(
        text("SELECT id, tx_id, block_number, chaincode_id, event_name FROM fabric_events ORDER BY id DESC LIMIT :l"),
        {"l": limit},
    ).fetchall()
    return {
        "items": [
            {"id": r[0], "tx_id": r[1], "block": r[2], "chaincode": r[3], "event": r[4]} for r in rows
        ]
    }

# =============================
# ⛓ Polygon Ledger Log
# =============================
@router.get("/polygon")
def polygon(limit: int = 200, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    rows = db.execute(
        text("""
        SELECT id, batch_code, tx_hash, block_number, status, published_at
        FROM blockchain_proofs
        ORDER BY id DESC LIMIT :l
        """),
        {"l": limit},
    ).fetchall()
    return {
        "items": [
            {
                "id": r[0],
                "batch_code": r[1],
                "tx_hash": r[2],
                "block": r[3],
                "status": r[4],
                "published_at": str(r[5]),
            }
            for r in rows
        ]
    }
