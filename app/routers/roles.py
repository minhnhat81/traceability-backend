from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.security import verify_jwt
import logging

logger = logging.getLogger("uvicorn")

router = APIRouter(prefix="/api/roles", tags=["roles"])


@router.get("/")
async def list_roles(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    📋 Lấy danh sách roles
    """
    try:
        result = await db.execute(
            text("""
                SELECT id, tenant_id, name, description
                FROM rbac_roles
                ORDER BY id
            """)
        )
        rows = result.fetchall()
        return [dict(r._mapping) for r in rows]
    except Exception as e:
        logger.error(f"[RBAC_ROLES] Query failed: {e}")
        return {"ok": False, "error": str(e)}


@router.post("/")
async def create_role(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ➕ Tạo role mới
    """
    try:
        await db.execute(
            text("""
                INSERT INTO rbac_roles (tenant_id, name, description)
                VALUES (:tenant_id, :name, :description)
            """),
            {
                "tenant_id": body.get("tenant_id") or user.get("tenant_id"),
                "name": body.get("name"),
                "description": body.get("description"),
            },
        )
        await db.commit()
        return {"ok": True, "message": "Role created successfully"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_ROLES] Insert failed: {e}")
        return {"ok": False, "error": str(e)}


@router.put("/{role_id}")
async def update_role(role_id: int, body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ✏️ Cập nhật role
    """
    try:
        await db.execute(
            text("""
                UPDATE rbac_roles
                SET tenant_id = COALESCE(:tenant_id, tenant_id),
                    name = COALESCE(:name, name),
                    description = COALESCE(:description, description)
                WHERE id = :id
            """),
            {
                "id": role_id,
                "tenant_id": body.get("tenant_id"),
                "name": body.get("name"),
                "description": body.get("description"),
            },
        )
        await db.commit()
        return {"ok": True, "message": f"Role {role_id} updated"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_ROLES] Update failed: {e}")
        return {"ok": False, "error": str(e)}


@router.delete("/{role_id}")
async def delete_role(role_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ❌ Xóa role
    """
    try:
        await db.execute(
            text("DELETE FROM rbac_roles WHERE id = :id"),
            {"id": role_id},
        )
        await db.commit()
        return {"ok": True, "message": f"Role {role_id} deleted"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_ROLES] Delete failed: {e}")
        return {"ok": False, "error": str(e)}
