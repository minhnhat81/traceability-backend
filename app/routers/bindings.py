from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.security import verify_jwt
import logging

logger = logging.getLogger("uvicorn")

router = APIRouter(prefix="/api/bindings", tags=["bindings"])


@router.get("/")
async def list_bindings(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    📋 Danh sách liên kết user-role (từ bảng rbac_role_bindings)
    """
    try:
        result = await db.execute(
            text("SELECT id, tenant_id, user_id, role_id FROM rbac_role_bindings ORDER BY id")
        )
        rows = result.fetchall()
        return [dict(r._mapping) for r in rows]
    except Exception as e:
        logger.error(f"[RBAC_BINDINGS] Query failed: {e}")
        return {"ok": False, "error": str(e), "rows": []}


@router.post("/")
async def create_binding(
    body: dict,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt)
):
    """
    ➕ Thêm mới một role binding (gán role cho user)
    """
    tenant_id = body.get("tenant_id") or user.get("tenant_id")
    user_id = body.get("user_id")
    role_id = body.get("role_id")

    if not user_id or not role_id:
        return {"ok": False, "error": "user_id and role_id are required"}

    try:
        await db.execute(
            text(
                "INSERT INTO rbac_role_bindings (tenant_id, user_id, role_id) "
                "VALUES (:t, :u, :r)"
            ),
            {"t": tenant_id, "u": user_id, "r": role_id},
        )
        await db.commit()
        return {"ok": True, "message": "Binding created successfully"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_BINDINGS] Insert failed: {e}")
        return {"ok": False, "error": str(e)}


@router.delete("/{binding_id}")
async def delete_binding(
    binding_id: int,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt)
):
    """
    ❌ Xóa role binding theo ID
    """
    try:
        await db.execute(
            text("DELETE FROM rbac_role_bindings WHERE id = :id"),
            {"id": binding_id},
        )
        await db.commit()
        return {"ok": True, "message": f"Binding {binding_id} deleted"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_BINDINGS] Delete failed: {e}")
        return {"ok": False, "error": str(e)}


@router.put("/{binding_id}")
async def update_binding(
    binding_id: int,
    body: dict,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt)
):
    """
    ✏️ Cập nhật role binding (tenant_id, user_id, role_id)
    """
    try:
        await db.execute(
            text(
                """
                UPDATE rbac_role_bindings
                SET tenant_id = COALESCE(:tenant_id, tenant_id),
                    user_id = COALESCE(:user_id, user_id),
                    role_id = COALESCE(:role_id, role_id)
                WHERE id = :id
                """
            ),
            {
                "tenant_id": body.get("tenant_id"),
                "user_id": body.get("user_id"),
                "role_id": body.get("role_id"),
                "id": binding_id,
            },
        )
        await db.commit()
        return {"ok": True, "message": f"Binding {binding_id} updated"}
    except Exception as e:
        await db.rollback()
        logger.error(f"[RBAC_BINDINGS] Update failed: {e}")
        return {"ok": False, "error": str(e)}
