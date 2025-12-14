
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from db import get_db
from app.security import verify_jwt, check_permission


router = APIRouter(prefix="/api/dpp-designer", tags=["dpp_designer"])

@router.post("/templates")
def create_template(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    db.execute(text("INSERT INTO dpp_templates(tenant_id,name,schema,mapping) VALUES (1,:n,:s,:m)"),
               {"n": body.get("name"), "s": body.get("schema"), "m": body.get("mapping")})
    db.commit(); return {"ok": True}

@router.get("/templates")
def list_templates(db: Session = Depends(get_db), user=Depends(verify_jwt)):
    rows = db.execute(text("SELECT id,name,schema,mapping,created_at FROM dpp_templates ORDER BY id DESC")).fetchall()
    return {"items":[{"id":r[0],"name":r[1],"schema":r[2],"mapping":r[3],"created_at":str(r[4])} for r in rows]}

@router.post("/preview")
def preview(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    """Render payload by applying mapping rules to sample data (very simple)."""
    schema = body.get("schema") or {}
    mapping = body.get("mapping") or {}
    sample = body.get("sample") or {}
    payload = {}
    for k,v in schema.items():
        src = mapping.get(k)
        if isinstance(src, str):
            payload[k] = sample.get(src)
        elif isinstance(src, dict) and 'const' in src:
            payload[k] = src['const']
        else:
            payload[k] = None
    return {"payload": payload}
