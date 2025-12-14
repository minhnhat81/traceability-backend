from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.security import verify_jwt
import logging

logger = logging.getLogger("uvicorn")

router = APIRouter(prefix="/api/scopes", tags=["scopes"])


@router.get("/")
async def list_scopes(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    📋 Danh sách scopes (quyền hành động RBAC)
    """
    try:
        result = await db.execute(
            text("""
                SELECT id, tenant_id, resource, action, constraint_expr
                FROM rbac_scopes
                ORDER BY id
            """)
        )
        rows = result.fetchall()
        return [dict(r._mapping) for r in rows]
    except Exception as e:
        logger.error(f"[RBAC_SCOPES] Query failed: {e}")
        return {"ok": False, "error": str(e), "rows": []}


@router.post("/")
async def create_scope(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ➕ Thêm mới một scope
    """
    try:
        await db.execute(
            text("""
                INSERT INTO rbac_scopes (tenant_id, resource, action, constraint_expr)
                VALUES (:tenant_id, :resource, :action, :constraint_expr)
            """),
            {
                "tenant_id": body.get("tenant_id") or user.get("tenant_id"),
                "resource": body.get("resource"),
                "action": body.get("action"),
                "constraint_expr": body.get("constraint_expr"),
            },
        )
        await db.commit()
        return {"ok": True, "message": "Scope created successfully"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_SCOPES] Insert failed: {e}")
        return {"ok": False, "error": str(e)}


@router.put("/{scope_id}")
async def update_scope(scope_id: int, body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ✏️ Cập nhật scope
    """
    try:
        await db.execute(
            text("""
                UPDATE rbac_scopes
                SET tenant_id = COALESCE(:tenant_id, tenant_id),
                    resource = COALESCE(:resource, resource),
                    action = COALESCE(:action, action),
                    constraint_expr = COALESCE(:constraint_expr, constraint_expr)
                WHERE id = :id
            """),
            {
                "id": scope_id,
                "tenant_id": body.get("tenant_id"),
                "resource": body.get("resource"),
                "action": body.get("action"),
                "constraint_expr": body.get("constraint_expr"),
            },
        )
        await db.commit()
        return {"ok": True, "message": f"Scope {scope_id} updated"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_SCOPES] Update failed: {e}")
        return {"ok": False, "error": str(e)}


@router.delete("/{scope_id}")
async def delete_scope(scope_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ❌ Xóa scope theo ID
    """
    try:
        await db.execute(
            text("DELETE FROM rbac_scopes WHERE id = :id"),
            {"id": scope_id},
        )
        await db.commit()
        return {"ok": True, "message": f"Scope {scope_id} deleted"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_SCOPES] Delete failed: {e}")
        return {"ok": False, "error": str(e)}
