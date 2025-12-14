from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.security import verify_jwt
import logging

logger = logging.getLogger("uvicorn")

router = APIRouter(prefix="/api/tenants", tags=["tenants"])


@router.get("/")
async def list_tenants(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        result = await db.execute(text("SELECT id, code, name FROM tenants ORDER BY id"))
        rows = result.fetchall()
        return [dict(r._mapping) for r in rows]
    except Exception as e:
        logger.error(f"[TENANTS] Query failed: {e}")
        return {"ok": False, "error": str(e)}


@router.post("/")
async def create_tenant(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        await db.execute(
            text("INSERT INTO tenants (code, name) VALUES (:code, :name)"),
            {"code": body.get("code"), "name": body.get("name")},
        )
        await db.commit()
        return {"ok": True, "message": "Tenant created successfully"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[TENANTS] Insert failed: {e}")
        return {"ok": False, "error": str(e)}


@router.put("/{tenant_id}")
async def update_tenant(tenant_id: int, body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        await db.execute(
            text(
                "UPDATE tenants SET code = COALESCE(:code, code), name = COALESCE(:name, name) WHERE id = :id"
            ),
            {"id": tenant_id, "code": body.get("code"), "name": body.get("name")},
        )
        await db.commit()
        return {"ok": True, "message": f"Tenant {tenant_id} updated"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[TENANTS] Update failed: {e}")
        return {"ok": False, "error": str(e)}


@router.delete("/{tenant_id}")
async def delete_tenant(tenant_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        await db.execute(text("DELETE FROM tenants WHERE id = :id"), {"id": tenant_id})
        await db.commit()
        return {"ok": True, "message": f"Tenant {tenant_id} deleted"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[TENANTS] Delete failed: {e}")
        return {"ok": False, "error": str(e)}
