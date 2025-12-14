
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from db import get_db
from app.security import verify_jwt, check_permission


router = APIRouter(prefix="/api/audit", tags=["audit"])

@router.get("/stats")
def stats(user_id: int|None = Query(None), endpoint: str|None = Query(None), days: int = 30, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    where = "1=1"
    params = {"days": days}
    if user_id:
        where += " AND user_id=:uid"; params["uid"]=user_id
    if endpoint:
        where += " AND endpoint ILIKE :ep"; params["ep"]=f"%{endpoint}%"
    daily = db.execute(text(f"""
        SELECT date_trunc('day', ts) AS d, count(*) 
        FROM audit_logs WHERE ts > now() - (:days || ' days')::interval AND {where}
        GROUP BY 1 ORDER BY 1
    """), params).fetchall()
    top_ep = db.execute(text(f"""
        SELECT endpoint, count(*) FROM audit_logs 
        WHERE ts > now() - (:days || ' days')::interval AND {where}
        GROUP BY 1 ORDER BY 2 DESC LIMIT 20
    """), params).fetchall()
    top_user = db.execute(text(f"""
        SELECT COALESCE(user_id,0), count(*) FROM audit_logs 
        WHERE ts > now() - (:days || ' days')::interval AND {where}
        GROUP BY 1 ORDER BY 2 DESC LIMIT 20
    """), params).fetchall()
    return {
        "daily":[{"date": str(r[0])[:10], "count": int(r[1])} for r in daily],
        "top_endpoints":[{"endpoint": r[0], "count": int(r[1])} for r in top_ep],
        "top_users":[{"user_id": int(r[0]), "count": int(r[1])} for r in top_user],
    }
