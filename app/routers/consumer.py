
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from db import get_db
from app.security import verify_jwt, check_permission


router = APIRouter(prefix="/api/consumer", tags=["consumer"])

@router.get("/scan")
def scan(code: str, db: Session = Depends(get_db)):  # public endpoint (no auth)
    # code can be product_code or EPC (simplified)
    dpp = db.execute(text("SELECT payload, version FROM dpp_passports WHERE product_code=:c ORDER BY id DESC LIMIT 1"), {"c": code}).fetchone()
    anchors = db.execute(text("SELECT tx_hash, network, ref FROM anchors WHERE ref=:r ORDER BY id DESC LIMIT 10"), {"r": code}).fetchall()
    return {"code": code, "dpp": dpp[0] if dpp else None, "version": dpp[1] if dpp else None,
            "anchors":[{"tx_hash":a[0],"network":a[1],"ref":a[2]} for a in anchors]}
