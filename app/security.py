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
# 🔧 Logging toàn cục
# =============================
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("uvicorn")
logger.setLevel(logging.DEBUG)

auth_scheme = HTTPBearer()

# =============================
# ✅ Verify JWT Token (có kiểm tra user DB)
# =============================
async def verify_jwt(
    creds: HTTPAuthorizationCredentials = Depends(auth_scheme),
    db: AsyncSession = Depends(get_db)
):
    token = creds.credentials

    # 🧩 Decode token: JWKS hoặc local
    if not getattr(settings, "JWKS_URL", None):
        secret_key = settings.JWT_SECRET or settings.SECRET_KEY or "secret-key-demo"
        algorithm = settings.JWT_ALGORITHM or "HS256"
        try:
            payload = jwt.decode(token, secret_key, algorithms=[algorithm])
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="Token expired")
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Invalid local token: {e}")
    else:
        try:
            with httpx.Client(timeout=10) as client:
                jwks = client.get(str(settings.JWKS_URL)).json()
            head = jwt.get_unverified_header(token)
            kid = head.get("kid")
            key = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
            if not key:
                raise Exception("kid not found in JWKS")

            public_key = jwt.algorithms.RSAAlgorithm.from_jwk(json.dumps(key))
            payload = jwt.decode(
                token,
                public_key,
                algorithms=[head["alg"]],
                options={"verify_aud": False},
            )
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Invalid token: {e}")

    logger.debug(f"[AUTH DEBUG] Raw JWT payload: {payload}")

    username = payload.get("sub") or payload.get("username")
    if not username:
        raise HTTPException(status_code=401, detail="Token missing 'sub' or 'username'")

    # ✅ Async execute (fix lỗi coroutine)
    result = await db.execute(
        _text("SELECT id, tenant_id, role, is_active FROM users WHERE username=:u OR email=:u"),
        {"u": username},
    )
    row = result.first()

    if not row:
        logger.warning(f"[AUTH WARN] user '{username}' not found in DB, fallback role=guest")
        payload.update({"id": 0, "tenant_id": 1, "role": "guest", "is_active": True})
        return payload

    if not row.is_active:
        raise HTTPException(status_code=403, detail="permission denied (inactive user)")

    payload.update({
        "id": row.id,
        "tenant_id": row.tenant_id or 1,
        "role": (row.role or "").strip().lower(),
        "is_active": row.is_active,
    })

    return payload


# =============================
# ✅ Scope helpers (Async)
# =============================
async def scope_where_clause(
    db: AsyncSession,
    user_payload: dict,
    resource: str,
    extra_filters: dict | None = None
) -> str:
    tenant_id = (user_payload or {}).get("tenant_id") or 1
    role = (user_payload or {}).get("role", "").lower()
    wh = f" tenant_id = {int(tenant_id)} "

    # ✅ Nếu là admin, không xem user admin/superadmin
    if resource == "users" and role in ("admin", "tenant_admin"):
        wh += " AND role NOT IN ('admin','superadmin') "

    try:
        # ✅ await bắt buộc vì db là AsyncSession
        result = await db.execute(
            _text(
                "SELECT resource, action, constraint_expr FROM scopes WHERE tenant_id=:t"
            ),
            {"t": tenant_id},
        )
        rows = result.fetchall()  # KHÔNG await ở đây

        for r in rows:
            res_name, action, constraint_expr = r
            if res_name == resource and action in ("read", "*") and constraint_expr:
                try:
                    filters = json.loads(constraint_expr)
                except Exception:
                    continue

                for k, vals in (filters or {}).items():
                    if isinstance(vals, list) and vals:
                        safe_vals = []
                        for v in vals:
                            vv = str(v).replace("'", "''")
                            safe_vals.append(f"'{vv}'")
                        wh += f" AND COALESCE({k},'') IN ({','.join(safe_vals)}) "
    except Exception as e:
        logger.warning(f"[SCOPE DEBUG] scope_where_clause failed: {e}")
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
# ✅ Audit & Permission
# =============================
def _write_audit(db, user, path, method, status, note=None):
    try:
        db.execute(
            _text(
                "INSERT INTO audit_logs(path, method, user_id, tenant_id, status, note) "
                "VALUES (:p,:m,:u,:t,:s,:n)"
            ),
            {
                "p": path,
                "m": method,
                "u": (user or {}).get("sub"),
                "t": (user or {}).get("tenant_id", 1),
                "s": status,
                "n": note,
            },
        )
        db.commit()
    except Exception as e:
        logger.warning(f"[AUDIT DEBUG] audit write failed: {e}")
        db.rollback()


def check_permission(db, user_payload, resource, action, body=None, path="/", method="POST"):
    tenant_id = (user_payload or {}).get("tenant_id") or 1
    role = (user_payload or {}).get("role", "").lower()

    if role == "superadmin":
        return True

    if role in ("admin", "tenant_admin") and resource == "users" and action in ("create", "update"):
        target_role = (body or {}).get("role")
        target_tenant = (body or {}).get("tenant_id")
        user_tenant = (user_payload or {}).get("tenant_id")
        if target_tenant == user_tenant and target_role in ("supplier", "data_staff"):
            return True

    _write_audit(db, user_payload, path, method, "VIOLATION", f"deny {resource}:{action}")
    return False


# =============================
# ✅ JWT creator
# =============================
def create_jwt(data: dict, expires_delta: timedelta | None = None) -> str:
    secret_key = settings.JWT_SECRET or settings.SECRET_KEY or "secret-key-demo"
    algorithm = settings.JWT_ALGORITHM or "HS256"
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=12))

    payload = data.copy()
    payload.update({"exp": expire, "sub": data.get("username") or data.get("email")})
    payload.setdefault("tenant_id", 1)

    token = jwt.encode(payload, secret_key, algorithm=algorithm)
    logger.debug(f"[AUTH DEBUG] JWT created for {payload.get('sub')} exp={expire}")
    return token
