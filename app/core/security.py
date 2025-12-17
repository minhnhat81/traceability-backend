import json 
import httpx
import jwt
import logging
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import text as _text
from app.core.config import settings
from app.core.db import get_db

# =============================
# 🔧 Cấu hình logging toàn cục
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
    db=Depends(get_db)
):
    token = creds.credentials

    # --- Dev mode: local verification ---
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
        # --- Remote JWKS verification ---
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                jwks = (await client.get(str(settings.JWKS_URL))).json()

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

    # --- Log payload sau khi decode ---
    logger.debug(f"[AUTH DEBUG] Raw JWT payload: {payload}")

    # --- Kiểm tra user trong DB ---
    username = payload.get("sub") or payload.get("username")
    if not username:
        raise HTTPException(status_code=401, detail="Token missing 'sub' or 'username'")

    result = await db.execute(
        _text(
            "SELECT id, tenant_id, role, is_active "
            "FROM users WHERE username=:u OR email=:u"
        ),
        {"u": username},
    )
    row = result.first()

    # ⚙️ Nếu không tìm thấy user trong DB → fallback tenant_id mặc định
    if not row:
        logger.warning(f"[AUTH WARN] user '{username}' not found in DB, using fallback tenant_id=1")
        payload["id"] = 0
        payload["tenant_id"] = 1
        payload["role"] = "guest"
        payload["is_active"] = True
        return payload

    logger.debug(
        f"[AUTH DEBUG] DB user found: username={username}, role={row.role}, "
        f"tenant_id={row.tenant_id}, is_active={row.is_active}"
    )

    if not row.is_active:
        raise HTTPException(status_code=403, detail="permission denied (inactive user)")

    # ✅ Ghi đè role & tenant_id trong payload bằng giá trị DB (chuẩn hóa)
    payload["id"] = row.id
    payload["tenant_id"] = row.tenant_id or 1  # 👈 fallback an toàn
    payload["role"] = (row.role or "").strip().lower()
    payload["is_active"] = row.is_active

    # ✅ Nếu token hoặc DB user không có tenant_id → dùng tenant_id=1
    if not payload.get("tenant_id"):
        logger.warning("[AUTH WARN] Missing tenant_id in payload → fallback = 1")
        payload["tenant_id"] = 1

    logger.debug(f"[AUTH DEBUG] Final payload after DB merge: {payload}")
    return payload


# =============================
# ✅ Các hàm scope / permission
# =============================
async def scope_constraints(db, tenant_id: int, user_sub: str, resource: str, action: str):
    result = await db.execute(
        _text("SELECT constraint FROM scopes WHERE tenant_id=:t AND resource=:r AND action=:a"),
        {"t": tenant_id, "r": resource, "a": action},
    )
    q = result.fetchall()
    constraints = [row[0] for row in q if row[0]]
    return {"tenant_id": tenant_id, "filters": constraints}


def sql_scope_clause(resource: str, constraints: dict):
    parts = []
    params = {}
    t = constraints.get("tenant_id")
    if t is not None:
        parts.append("tenant_id = :_tenant_id")
        params["_tenant_id"] = t
    allow_products = set()
    allow_batches = set()
    for c in constraints.get("filters", []):
        if not isinstance(c, dict):
            continue
        for k, v in c.items():
            if k == "product_code":
                allow_products.update(v if isinstance(v, list) else [v])
            if k == "batch_code":
                allow_batches.update(v if isinstance(v, list) else [v])
    if allow_products:
        parts.append("product_code = ANY(:_prod_arr)")
        params["_prod_arr"] = list(allow_products)
    if allow_batches:
        parts.append("batch_code = ANY(:_batch_arr)")
        params["_batch_arr"] = list(allow_batches)
    where = " AND ".join(parts) if parts else "1=1"
    return where, params


async def scope_where_clause(db, user_payload, resource: str, extra_filters: dict | None = None) -> str:
    tenant_id = (user_payload or {}).get("tenant_id") or 1
    wh = f" tenant_id = {int(tenant_id)} "

    try:
        result = await db.execute(
            _text("SELECT resource, action, constraint FROM scopes WHERE tenant_id=:t"),
            {"t": tenant_id},
        )
        rows = result.fetchall()
        for r in rows:
            if r[0] == resource and r[1] in ("read", "*") and r[2]:
                for k, vals in (r[2] or {}).items():
                    if isinstance(vals, list) and vals:
                        safe_vals = []
                        for v in vals:
                            vv = str(v).replace("'", "''")
                            safe_vals.append(f"'{vv}'")
                        safe = ",".join(safe_vals)
                        wh += f" AND COALESCE({k},'') IN ({safe}) "

    except Exception as e:
        logger.warning(f"[SCOPE DEBUG] scope_where_clause failed: {e}")

    if extra_filters:
        for k, v in extra_filters.items():
            if v is not None:
                wh += f" AND {k} = :{k} "
    return wh


async def _write_audit(db, user, path, method, status, note=None):
    try:
        await db.execute(
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
        await db.commit()
    except Exception as e:
        logger.warning(f"[AUDIT DEBUG] audit write failed: {e}")
        await db.rollback()


# =============================
# ✅ Hàm kiểm tra quyền chính
# =============================
async def check_permission(
    db,
    user_payload,
    resource: str,
    action: str,
    body: dict | None = None,
    path: str = "/",
    method: str = "POST",
):
    tenant_id = (
        getattr(user_payload, "tenant_id", None)
        or (user_payload or {}).get("tenant_id")
        or 1
    )
    role = (
        getattr(user_payload, "role", None)
        or (user_payload or {}).get("role")
        or ""
    )
    role = str(role).strip().lower()

    logger.debug(
        f"[AUTH DEBUG] check_permission() → role={role}, resource={resource}, action={action}, tenant_id={tenant_id}"
    )

    if role in ("platform_admin", "tenant_admin", "system_admin", "consortium_admin"):
        logger.debug(f"[AUTH DEBUG] role={role} bypass scope check ({resource}:{action}) ✅")
        return True

    try:
        result = await db.execute(
            _text("SELECT resource, action, constraint FROM scopes WHERE tenant_id=:t"),
            {"t": tenant_id},
        )
        rows = result.fetchall()
        for r in rows:
            res, act, cons = r[0], r[1], r[2]
            if res == resource and (act == action or act == "*"):
                if not cons:
                    logger.debug(f"[AUTH DEBUG] allow by scope {res}:{act} (no constraint)")
                    return True
                ok = True
                for k, vals in (cons or {}).items():
                    if isinstance(vals, list) and vals:
                        v = (body or {}).get(k)
                        if v is None or v not in vals:
                            ok = False
                            break
                if ok:
                    logger.debug(f"[AUTH DEBUG] allow by constraint {res}:{act}")
                    return True
    except Exception as e:
        logger.warning(f"[AUTH DEBUG] check_permission error: {e}")

    await _write_audit(db, user_payload, path, method, "VIOLATION", note=f"deny {resource}:{action}")
    return False


# =============================
# ✅ Hàm tạo JWT Token (bổ sung)
# =============================
def create_jwt(data: dict, expires_delta: timedelta | None = None) -> str:
    """
    📦 Sinh JWT token từ payload user.
    """
    secret_key = settings.JWT_SECRET or settings.SECRET_KEY or "secret-key-demo"
    algorithm = settings.JWT_ALGORITHM or "HS256"
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=12))

    payload = data.copy()
    payload.update({"exp": expire, "sub": data.get("username") or data.get("email")})

    # ✅ Fallback tenant_id nếu thiếu
    if "tenant_id" not in payload:
        payload["tenant_id"] = 1

    token = jwt.encode(payload, secret_key, algorithm=algorithm)
    logger.debug(f"[AUTH DEBUG] JWT created for user={payload.get('sub')} exp={expire}")
    return token
