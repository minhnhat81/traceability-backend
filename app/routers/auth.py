from datetime import datetime, timedelta
from typing import Optional
import traceback

from fastapi import APIRouter, Depends, HTTPException, status
import jwt   # ✅ DÙNG PYJWT (KHÔNG DÙNG python-jose)
from passlib.context import CryptContext
from pydantic import BaseModel
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.config import settings
from app.models.user import User

# ==========================================================
# Router
# ==========================================================
router = APIRouter(prefix="/auth", tags=["auth"])

# ==========================================================
# JWT config (CHỐT 1 SECRET DUY NHẤT)
# ==========================================================
if not settings.JWT_SECRET:
    raise RuntimeError("JWT_SECRET is not set in environment")

SECRET_KEY = settings.JWT_SECRET
ALGORITHM = settings.JWT_ALGORITHM or "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# ==========================================================
# Password hashing
# ==========================================================
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)

# ==========================================================
# Schemas
# ==========================================================
class LoginRequest(BaseModel):
    username: str
    password: str


class UserResponse(BaseModel):
    username: str
    email: Optional[str]
    role: str
    tenant_id: int
    name: Optional[str]


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# ==========================================================
# Utils
# ==========================================================
def verify_password(plain_password: str, hashed_password: Optional[str]) -> bool:
    if not hashed_password:
        return False
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception:
        return False


def create_access_token(
    data: dict,
    expires_delta: Optional[timedelta] = None,
) -> str:
    payload = data.copy()
    expire = datetime.utcnow() + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload["exp"] = expire

    # ✅ PYJWT
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# ==========================================================
# Login endpoint
# ==========================================================
@router.post(
    "/login",
    response_model=LoginResponse,
    status_code=status.HTTP_200_OK,
)
async def login(
    data: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    try:
        stmt = select(User).where(
            or_(
                User.username == data.username,
                User.email == data.username,
            )
        )

        result = await db.execute(stmt)
        user = result.scalars().first()

        if not user:
            raise HTTPException(status_code=401, detail="Invalid username or password")

        if not getattr(user, "is_active", True):
            raise HTTPException(status_code=403, detail="User account is inactive")

        if not verify_password(data.password, user.password_hash):
            raise HTTPException(status_code=401, detail="Invalid username or password")

        token_payload = {
            "sub": user.username,
            "user_id": user.id,
            "role": user.role,
            "tenant_id": user.tenant_id,
        }

        access_token = create_access_token(token_payload)

        return LoginResponse(
            access_token=access_token,
            user=UserResponse(
                username=user.username,
                email=user.email,
                role=user.role,
                tenant_id=user.tenant_id,
                name=user.name,
            ),
        )

    except HTTPException:
        raise
    except Exception as e:
        print("🔥 LOGIN ERROR:", e)
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Internal auth error")
