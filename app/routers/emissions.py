
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission, scope_where_clause

router = APIRouter(prefix="/api/emissions", tags=["emissions"])

@router.get("/factors")
def list_factors(db: Session = Depends(get_db), user=Depends(verify_jwt)):
    rows = db.execute(text("SELECT id,name,scope,factor,unit,source FROM emissions_factors WHERE " + scope_where_clause(db,user,'emissions_factors') + " ORDER BY id DESC")).fetchall()
    return {"items":[{"id":r[0],"name":r[1],"scope":r[2],"factor":r[3],"unit":r[4],"source":r[5]} for r in rows]}

@router.post("/factors")
def add_factor(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    db.execute(text("INSERT INTO emissions_factors(tenant_id,name,scope,factor,unit,source) VALUES (1,:n,:s,:f,:u,:so)"),
               {"n": body.get("name"), "s": int(body.get("scope",1)), "f": float(body.get("factor",0)), "u": body.get("unit"), "so": body.get("source")})
    db.commit(); return {"ok": True}

@router.get("/records")
def list_records(db: Session = Depends(get_db), user=Depends(verify_jwt)):
    rows = db.execute(text("SELECT id,scope,activity,quantity,unit,factor FROM emissions_records WHERE " + scope_where_clause(db,user,'emissions_records') + " ORDER BY id DESC")).fetchall()
    return {"items":[{"id":r[0],"scope":r[1],"activity":r[2],"quantity":r[3],"unit":r[4],"factor":r[5]} for r in rows]}

@router.post("/records")
def add_record(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    db.execute(text("INSERT INTO emissions_records(tenant_id,scope,activity,quantity,unit,factor) VALUES (1,:s,:a,:q,:u,:f)"),
               {"s": int(body.get("scope",1)), "a": body.get("activity"), "q": float(body.get("quantity",0)), "u": body.get("unit"), "f": float(body.get("factor",0))})
    db.commit(); return {"ok": True}

@router.get("/stats")
def stats(db: Session = Depends(get_db), user=Depends(verify_jwt)):
    rows = db.execute(text("SELECT scope, SUM(quantity*factor) AS t FROM emissions_records WHERE " + scope_where_clause(db,user,'emissions_records') + " GROUP BY scope ORDER BY scope")).fetchall()
    return {"by_scope":[{"scope": int(r[0]), "tco2e": float(r[1] or 0)} for r in rows]}
