from fastapi import APIRouter, Depends, HTTPException, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission, scope_where_clause
from passlib.hash import bcrypt
import secrets
import logging
import inspect

router = APIRouter(prefix="/api/users", tags=["users"])
logger = logging.getLogger("uvicorn")

# ----------------------------------------------------------
# 🧩 Role definitions
# ----------------------------------------------------------
ALLOWED_ROLES = {"superadmin", "admin", "tenant_admin", "data_staff", "supplier", "farm", "manufacturer", "brand"}
CREATOR_ROLES = {"superadmin", "admin", "tenant_admin"}


def _norm_role(v: str | None) -> str:
    v = (v or "").strip().lower()
    if v not in ALLOWED_ROLES:
        raise HTTPException(400, f"invalid role '{v}', must be one of {sorted(ALLOWED_ROLES)}")
    return v


# ----------------------------------------------------------
# 🧩 Helpers
# ----------------------------------------------------------
async def safe_execute(db, sql, params=None):
    params = params or {}
    if isinstance(db, AsyncSession):
        return await db.execute(text(sql), params)
    else:
        return db.execute(text(sql), params)

async def safe_commit(db):
    """Tự động commit tương thích async/sync session"""
    if isinstance(db, AsyncSession):
        await db.commit()
    else:
        db.commit()


# ----------------------------------------------------------
# 📋 List Users
# ----------------------------------------------------------
@router.get("")
async def list_users(
    q: str | None = Query(None),
    db=Depends(get_db),
    user=Depends(verify_jwt)
):
    if not user or (user.get("is_active", True) is False):
        raise HTTPException(403, "permission denied (inactive user)")

    # Xác định where clause từ scope
    if inspect.iscoroutinefunction(scope_where_clause):
        where = await scope_where_clause(db, user, "users")
    else:
        where = scope_where_clause(db, user, "users")

    sql = f"SELECT id, tenant_id, username, email, name, role FROM users WHERE {where}"
    params = {}
    if q:
        sql += " AND (email ILIKE :q OR name ILIKE :q OR username ILIKE :q)"
        params["q"] = f"%{q}%"
    sql += " ORDER BY id DESC"

    result = await safe_execute(db, sql, params)
    rows = result.all()

    return {
        "items": [
            {
                "id": r.id,
                "tenant_id": r.tenant_id,
                "username": r.username,
                "email": r.email,
                "name": r.name,
                "role": r.role,
            }
            for r in rows
        ]
    }


# ----------------------------------------------------------
# ➕ Create User
# ----------------------------------------------------------
@router.post("")
async def create_user(body: dict, db=Depends(get_db), user=Depends(verify_jwt)):
    if not user or (user.get("is_active", True) is False):
        raise HTTPException(403, "permission denied (inactive user)")

    caller_role = (user.get("role") or "").strip().lower()
    if caller_role not in CREATOR_ROLES:
        raise HTTPException(403, "permission denied (role not allowed)")

    target_tenant = body.get("tenant_id") or user.get("tenant_id")
    if caller_role in {"admin", "tenant_admin"} and target_tenant != user.get("tenant_id"):
        raise HTTPException(403, "cannot create user in another tenant")

    new_role = _norm_role(body.get("role", "supplier"))
    if caller_role in {"admin", "tenant_admin"} and new_role not in {"supplier", "data_staff", "farm", "manufacturer", "brand"}:
        raise HTTPException(403, "admin can only create supplier or data_staff")

    username = body.get("username")
    if not username:
        email = body.get("email")
        username = email.split("@")[0] if (email and "@" in email) else f"user_{secrets.token_hex(4)}"

    dup_check = await safe_execute(
        db,
        "SELECT id FROM users WHERE username=:u OR email=:e",
        {"u": username, "e": body.get("email")},
    )
    if dup_check.first():
        raise HTTPException(400, "username or email already exists")

    pwd = body.get("password") or secrets.token_urlsafe(8)
    ph = bcrypt.hash(pwd)

    await safe_execute(
        db,
        "INSERT INTO users(tenant_id, username, email, name, role, password_hash, created_at, is_active) "
        "VALUES (:t, :u, :e, :n, :r, :p, NOW(), TRUE)",
        {"t": target_tenant, "u": username, "e": body["email"], "n": body.get("name"), "r": new_role, "p": ph},
    )
    await safe_commit(db)
    return {"ok": True, "username": username, "temp_password": pwd}


# ----------------------------------------------------------
# ✏️ Update User
# ----------------------------------------------------------
@router.put("/{user_id}")
async def update_user(
    user_id: int = Path(..., gt=0),
    body: dict = None,
    db=Depends(get_db),
    user=Depends(verify_jwt)
):
    if not user:
        raise HTTPException(403, "unauthorized")

    caller_role = (user.get("role") or "").lower()
    result = await safe_execute(db, "SELECT tenant_id, role FROM users WHERE id=:id", {"id": user_id})
    target = result.first()
    if not target:
        raise HTTPException(404, "user not found")

    target_tenant, target_role = target
    if caller_role in {"admin", "tenant_admin"} and target_tenant != user.get("tenant_id"):
        raise HTTPException(403, "cannot edit user from another tenant")
    if caller_role in {"admin", "tenant_admin"} and target_role in {"admin", "tenant_admin", "superadmin"}:
        raise HTTPException(403, "cannot edit higher privilege users")

    updates, params = [], {"id": user_id}
    if "email" in body:
        updates.append("email=:email")
        params["email"] = body["email"]
    if "name" in body:
        updates.append("name=:name")
        params["name"] = body["name"]
    if "role" in body:
        new_role = _norm_role(body["role"])
        if caller_role in {"admin", "tenant_admin"} and new_role not in {"supplier", "data_staff", "manufacturer", "brand"}:
            raise HTTPException(403, "admin can only assign supplier or data_staff")
        updates.append("role=:role")
        params["role"] = new_role

    if not updates:
        raise HTTPException(400, "no fields to update")

    await safe_execute(db, f"UPDATE users SET {', '.join(updates)} WHERE id=:id", params)
    await safe_commit(db)
    return {"ok": True, "updated": user_id}


# ----------------------------------------------------------
# ❌ Delete User
# ----------------------------------------------------------
@router.delete("/{user_id}")
async def delete_user(
    user_id: int = Path(..., gt=0),
    db=Depends(get_db),
    user=Depends(verify_jwt)
):
    if not user:
        raise HTTPException(403, "unauthorized")

    caller_role = (user.get("role") or "").lower()
    result = await safe_execute(db, "SELECT tenant_id, role FROM users WHERE id=:id", {"id": user_id})
    target = result.first()
    if not target:
        raise HTTPException(404, "user not found")

    target_tenant, target_role = target
    if caller_role in {"admin", "tenant_admin"} and target_tenant != user.get("tenant_id"):
        raise HTTPException(403, "cannot delete user from another tenant")
    if caller_role in {"admin", "tenant_admin"} and target_role in {"admin", "tenant_admin", "superadmin"}:
        raise HTTPException(403, "cannot delete higher privilege users")

    await safe_execute(db, "DELETE FROM users WHERE id=:id", {"id": user_id})
    await safe_commit(db)
    return {"ok": True, "deleted": user_id}


# ----------------------------------------------------------
# 🔑 Reset Password
# ----------------------------------------------------------
@router.post("/{user_id}/reset-password")
async def reset_password(
    user_id: int,
    db=Depends(get_db),
    user=Depends(verify_jwt)
):
    if not user:
        raise HTTPException(403, "unauthorized")

    caller_role = (user.get("role") or "").lower()
    result = await safe_execute(db, "SELECT tenant_id FROM users WHERE id=:id", {"id": user_id})
    target = result.first()
    if not target:
        raise HTTPException(404, "user not found")

    target_tenant = target[0]
    if caller_role in {"admin", "tenant_admin"} and target_tenant != user.get("tenant_id"):
        raise HTTPException(403, "cannot reset password for another tenant")

    pwd = secrets.token_urlsafe(8)
    ph = bcrypt.hash(pwd)
    await safe_execute(db, "UPDATE users SET password_hash=:p WHERE id=:id", {"p": ph, "id": user_id})
    await safe_commit(db)
    return {"ok": True, "temp_password": pwd}
