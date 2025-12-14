
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from db import get_db
from app.security import verify_jwt, check_permission, scope_where_clause

router = APIRouter(prefix="/api/customers", tags=["customers"])

@router.get("")
def list_customers(q: str | None = Query(None), db: Session = Depends(get_db), user=Depends(verify_jwt)):
    where = scope_where_clause(db, user, 'customers')
    sql = "SELECT id, code, name, country, contact FROM customers WHERE " + where
    params = {}
    if q:
        sql += " AND (code ILIKE :q OR name ILIKE :q OR country ILIKE :q)"
        params['q'] = f"%{q}%"
    sql += " ORDER BY id DESC"
    rows = db.execute(text(sql), params).fetchall()
    return {'items':[{'id':r[0],'code':r[1],'name':r[2],'country':r[3],'contact':r[4]} for r in rows]}

@router.post("")
def create_customer(body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    if not check_permission(db, user, 'customers', 'create', body, path='/api/customers', method='POST'):
        raise HTTPException(403, 'permission denied')
    db.execute(text("INSERT INTO customers(tenant_id,code,name,country,contact,meta) VALUES (1,:c,:n,:y,:ct,:m)"),
               {"c": body.get("code"), "n": body.get("name"), "y": body.get("country"), "ct": body.get("contact"), "m": body.get("meta")})
    db.commit(); return {"ok": True}

@router.put("/{customer_id}")
def update_customer(customer_id:int, body: dict, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    if not check_permission(db, user, 'customers', 'update', body, path='/api/customers', method='PUT'):
        raise HTTPException(403, 'permission denied')
    db.execute(text("UPDATE customers SET code=:c, name=:n, country=:y, contact=:ct, meta=:m WHERE id=:id"),
               {"c": body.get("code"), "n": body.get("name"), "y": body.get("country"), "ct": body.get("contact"), "m": body.get("meta"), "id": customer_id})
    db.commit(); return {"ok": True}

@router.delete("/{customer_id}")
def delete_customer(customer_id:int, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    if not check_permission(db, user, 'customers', 'delete', {}, path='/api/customers', method='DELETE'):
        raise HTTPException(403, 'permission denied')
    db.execute(text("DELETE FROM customers WHERE id=:id"), {"id": customer_id})
    db.commit(); return {"ok": True}
