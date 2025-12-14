
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission

router = APIRouter(prefix="/api/market", tags=["market_configs"])

@router.get("")
def get_latest(db: Session = Depends(get_db), user=Depends(verify_jwt)):
    row = db.execute(text("SELECT id, evfta, cptpp, eu_dpp, uflpa, updated_at FROM market_configs ORDER BY id DESC LIMIT 1")).fetchone()
    if not row: return {"evfta":{}, "cptpp":{}, "eu_dpp":{}, "uflpa":{}}
    return {"id": row[0], "evfta": row[1], "cptpp": row[2], "eu_dpp": row[3], "uflpa": row[4], "updated_at": str(row[5])}

@router.post("")
def upsert(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    db.execute(text("INSERT INTO market_configs(tenant_id,evfta,cptpp,eu_dpp,uflpa) VALUES (1,:ev,:cp,:ed,:uf)"),
               {"ev": body.get("evfta"), "cp": body.get("cptpp"), "ed": body.get("eu_dpp"), "uf": body.get("uflpa")})
    db.commit(); return {"ok": True}
