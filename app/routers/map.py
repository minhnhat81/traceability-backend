
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission, scope_where_clause
from datetime import datetime

router = APIRouter(prefix="/api/map", tags=["map"])

@router.get("/nodes")
def nodes(batch_code: str | None = None, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    # suppliers -> factories
    where_sup = scope_where_clause(db, user, 'suppliers')
    rs = db.execute(text("SELECT id, code, name, country FROM suppliers WHERE " + where_sup)).fetchall()
    rf = db.execute(text("SELECT id, supplier_id, name, location FROM factories")).fetchall()
    nodes = [{"type":"supplier","id":s[0],"code":s[1],"name":s[2],"country":s[3]} for s in rs]
    for f in rf:
        nodes.append({"type":"factory","id":f[0],"supplier_id":f[1],"name":f[2],"location":f[3]})
    # ports from batches (rough)
    if batch_code:
        b = db.execute(text("SELECT code, country FROM batches WHERE code=:c"), {"c": batch_code}).fetchone()
        if b: nodes.append({"type":"port","code": "PORT-"+b[0], "country": b[1]})
    return {"items": nodes}

@router.get("/flows")
def flows(batch_code: str | None = None,
          date_from: str | None = Query(None), date_to: str | None = Query(None),
          db: Session = Depends(get_db), user=Depends(verify_jwt)):
    where_evt = scope_where_clause(db, user, 'events')
    q = "SELECT batch_code, event_time, biz_step, read_point, biz_location FROM epcis_events WHERE " + where_evt
    params = {}
    if batch_code:
        q += " AND batch_code = :b"; params["b"]=batch_code
    if date_from:
        q += " AND event_time >= :df"; params["df"]=date_from
    if date_to:
        q += " AND event_time <= :dt"; params["dt"]=date_to
    q += " ORDER BY event_time"
    rows = db.execute(text(q), params).fetchall()
    flows = []
    last = None
    for r in rows:
        cur = {"batch_code": r[0], "when": r[1], "where": r[4] or r[3], "biz_step": r[2]}
        if last:
            flows.append({"from": last["where"], "to": cur["where"], "biz_step": cur["biz_step"], "at": str(cur["when"])})
        last = cur
    return {"items": flows}
