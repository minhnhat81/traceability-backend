
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission


router = APIRouter(prefix="/api/compliance", tags=["compliance"])

@router.post("/fta")
def check_fta(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    # Stub: rule engine simplified -> mark pass if has at least 1 EPCIS event with biz_step like packing
    batch = body.get("batch_code")
    has_packing = db.execute(text("SELECT 1 FROM epcis_events WHERE batch_code=:b AND biz_step LIKE '%packing%' LIMIT 1"), {"b": batch}).scalar()
    passed = bool(has_packing)
    db.execute(text("INSERT INTO compliance_results(tenant_id,batch_code,scheme,pass_flag,details) VALUES (1,:b,'EVFTA',:p,'{}')"),
               {"b": batch, "p": passed})
    db.commit(); return {"ok": True, "pass": passed}

@router.post("/uflpa")
def check_uflpa(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    # Stub: pass if no supplier country is 'CN' in batch
    batch = body.get("batch_code")
    country = db.execute(text("SELECT country FROM batches WHERE code=:b"), {"b": batch}).scalar()
    passed = (country or "").upper() != "CN"
    db.execute(text("INSERT INTO compliance_results(tenant_id,batch_code,scheme,pass_flag,details) VALUES (1,:b,'UFLPA',:p,'{}')"),
               {"b": batch, "p": passed})
    db.commit(); return {"ok": True, "pass": passed}

@router.post("/dpp")
def check_dpp(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    # Stub: pass if product has DPP
    product = body.get("product_code")
    has_dpp = db.execute(text("SELECT 1 FROM dpp_passports WHERE product_code=:p LIMIT 1"), {"p": product}).scalar()
    passed = bool(has_dpp)
    db.execute(text("INSERT INTO compliance_results(tenant_id,batch_code,scheme,pass_flag,details) VALUES (1,:b,'DPP',:p,'{}')"),
               {"b": body.get("batch_code","N/A"), "p": passed})
    db.commit(); return {"ok": True, "pass": passed}
