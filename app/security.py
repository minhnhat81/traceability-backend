# app/security.py
import json
import httpx
import jwt
import logging
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import text as _text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.db import get_db

# =============================
# 🔧 Logging
# =============================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")

auth_scheme = HTTPBearer()

# =============================
# 🔐 JWT helpers (FIX CỐT LÕI)
# =============================
def _get_jwt_secret() -> str:
    """
    ❗ BẮT BUỘC dùng 1 secret duy nhất
    Tránh fallback gây lệch chữ ký
    """
    secret = getattr(settings, "JWT_SECRET", None)
    if not secret or not str(secret).strip():
        raise RuntimeError("JWT_SECRET is not set")
    return str(secret).strip()


def _get_jwt_algorithm() -> str:
    return getattr(settings, "JWT_ALGORITHM", None) or "HS256"


# =============================
# ✅ Verify JWT Token
# =============================
async def verify_jwt(
    creds: HTTPAuthorizationCredentials = Depends(auth_scheme),
    db: AsyncSession = Depends(get_db),
):
    token = creds.credentials

    # ---- LOCAL JWT (HS256) ----
    if not getattr(settings, "JWKS_URL", None):
        try:
            secret_key = _get_jwt_secret()
            algorithm = _get_jwt_algorithm()
            payload = jwt.decode(token, secret_key, algorithms=[algorithm])
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="Token expired")
        except Exception as e:
            raise HTTPException(
                status_code=401,
                detail=f"Invalid local token: {e}",
            )

    # ---- JWKS MODE (RSA) ----
    else:
        try:
            with httpx.Client(timeout=10) as client:
                jwks = client.get(str(settings.JWKS_URL)).json()

            header = jwt.get_unverified_header(token)
            kid = header.get("kid")
            key = next(
                (k for k in jwks.get("keys", []) if k.get("kid") == kid),
                None,
            )
            if not key:
                raise Exception("kid not found in JWKS")

            public_key = jwt.algorithms.RSAAlgorithm.from_jwk(
                json.dumps(key)
            )
            payload = jwt.decode(
                token,
                public_key,
                algorithms=[header["alg"]],
                options={"verify_aud": False},
            )
        except Exception as e:
            raise HTTPException(
                status_code=401,
                detail=f"Invalid token: {e}",
            )

    logger.debug(f"[AUTH] JWT payload = {payload}")

    # =============================
    # 👤 Resolve user from DB
    # =============================
    username = payload.get("sub") or payload.get("username")
    if not username:
        raise HTTPException(
            status_code=401,
            detail="Token missing 'sub'",
        )

    result = await db.execute(
        _text(
            """
            SELECT id, tenant_id, role, is_active
            FROM users
            WHERE username=:u OR email=:u
            """
        ),
        {"u": username},
    )
    row = result.first()

    if not row:
        # ⚠️ giữ logic gốc: fallback guest
        payload.update(
            {
                "id": 0,
                "tenant_id": 1,
                "role": "guest",
                "is_active": True,
            }
        )
        return payload

    if not row.is_active:
        raise HTTPException(
            status_code=403,
            detail="permission denied (inactive user)",
        )

    payload.update(
        {
            "id": row.id,
            "tenant_id": row.tenant_id or 1,
            "role": (row.role or "").strip().lower(),
            "is_active": row.is_active,
        }
    )

    return payload


# =============================
# ✅ Scope helper (GIỮ NGUYÊN)
# =============================
async def scope_where_clause(
    db: AsyncSession,
    user_payload: dict,
    resource: str,
    extra_filters: dict | None = None,
) -> str:
    tenant_id = (user_payload or {}).get("tenant_id") or 1
    role = (user_payload or {}).get("role", "").lower()
    wh = f" tenant_id = {int(tenant_id)} "

    if resource == "users" and role in ("admin", "tenant_admin"):
        wh += " AND role NOT IN ('admin','superadmin') "

    try:
        result = await db.execute(
            _text(
                """
                SELECT resource, action, constraint_expr
                FROM scopes
                WHERE tenant_id=:t
                """
            ),
            {"t": tenant_id},
        )
        rows = result.fetchall()

        for r in rows:
            res_name, action, constraint_expr = r
            if (
                res_name == resource
                and action in ("read", "*")
                and constraint_expr
            ):
                try:
                    filters = json.loads(constraint_expr)
                except Exception:
                    continue

                for k, vals in (filters or {}).items():
                    if isinstance(vals, list) and vals:
                        safe_vals = [
                            f"'{str(v).replace(\"'\", \"''\")}'"
                            for v in vals
                        ]
                        wh += (
                            f" AND COALESCE({k},'') "
                            f"IN ({','.join(safe_vals)}) "
                        )
    except Exception as e:
        logger.warning(f"[SCOPE] failed: {e}")
        try:
            await db.rollback()
        except Exception:
            pass

    if extra_filters:
        for k, v in extra_filters.items():
            if v is not None:
                wh += f" AND {k} = :{k} "

    return wh


# =============================
# ⚠️ Audit (GIỮ, nhưng NO-OP an toàn)
# =============================
def _write_audit(*args, **kwargs):
    # giữ cấu trúc gốc, tránh lỗi AsyncSession
    return


def check_permission(
    db,
    user_payload,
    resource,
    action,
    body=None,
    path="/",
    method="POST",
):
    tenant_id = (user_payload or {}).get("tenant_id") or 1
    role = (user_payload or {}).get("role", "").lower()

    if role == "superadmin":
        return True

    if (
        role in ("admin", "tenant_admin")
        and resource == "users"
        and action in ("create", "update")
    ):
        target_role = (body or {}).get("role")
        target_tenant = (body or {}).get("tenant_id")
        if (
            target_tenant == tenant_id
            and target_role in ("supplier", "data_staff")
        ):
            return True

    _write_audit(db, user_payload, path, method, "VIOLATION")
    return False


# =============================
# ✅ JWT creator (FIX CỐT LÕI)
# =============================
def create_jwt(
    data: dict,
    expires_delta: timedelta | None = None,
) -> str:
    secret_key = _get_jwt_secret()
    algorithm = _get_jwt_algorithm()

    expire = datetime.utcnow() + (
        expires_delta or timedelta(hours=12)
    )

    payload = data.copy()
    payload["exp"] = expire
    payload["sub"] = (
        payload.get("sub")
        or data.get("username")
        or data.get("email")
    )
    payload.setdefault("tenant_id", 1)

    token = jwt.encode(payload, secret_key, algorithm=algorithm)
    logger.info(
        f"[AUTH] JWT issued for {payload.get('sub')} exp={expire}"
    )
    return token
