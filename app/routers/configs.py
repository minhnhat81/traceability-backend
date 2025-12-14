from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.core.db import get_db
from app.utils.auth import verify_jwt

router = APIRouter(prefix="/api/configs", tags=["configs"])

@router.get("")
def get_configs(db: Session = Depends(get_db), user=Depends(verify_jwt)):
    row = db.execute(text("SELECT id, fabric, polygon, active FROM configs ORDER BY id ASC LIMIT 1")).fetchone()
    if not row:
        return {"fabric": None, "polygon": None, "active": False}
    return {"id": row[0], "fabric": row[1], "polygon": row[2], "active": bool(row[3])}

@router.post("")
def upsert_configs(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    fabric = body.get("fabric")
    polygon = body.get("polygon")
    active = bool(body.get("active", True))
    try:
        row = db.execute(text("SELECT id FROM configs ORDER BY id ASC LIMIT 1")).fetchone()
        if row:
            db.execute(text("UPDATE configs SET fabric=:f, polygon=:p, active=:a WHERE id=:id"),
                       {"f": fabric, "p": polygon, "a": active, "id": row[0]})
        else:
            db.execute(text("INSERT INTO configs(fabric, polygon, active) VALUES (:f,:p,:a)"),
                       {"f": fabric, "p": polygon, "a": active})
        db.commit()
        return {"ok": True}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))
