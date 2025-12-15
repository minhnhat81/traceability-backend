from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from jose import jwt
from passlib.context import CryptContext
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession  # ✅ BẮT BUỘC
from app.core.db import get_db
from app.models.user import User

# ===================================
# 🔧 Cấu hình & Router
# ===================================
router = APIRouter(prefix="/auth", tags=["auth"])

SECRET_KEY = "secret-key-demo"  # ⚠️ nên load từ .env hoặc settings
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Hash context duy nhất
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ===================================
# ✅ Hàm tiện ích
# ===================================
def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception:
        return False


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: timedelta | None = None) -> str:
    """Tạo JWT token."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# ===================================
# 🚪 API: Đăng nhập
# ===================================
@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),  # 👈 ép kiểu rõ
):
    query = select(User).where(
        or_(
            User.username == form_data.username,
            User.email == form_data.username,
        )
    )

    result = await db.execute(query)   # ✅ BẮT BUỘC await
    user = result.scalars().first()
    print("USER =", user)                       # 👈
    print("FIELDS =", user.__dict__ if user else None)  # 👈
    if not user:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="User account is inactive")

    if not verify_password(form_data.password, user.password_hash or ""):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    access_token = create_access_token({
        "sub": user.username,
        "role": user.role,
        "tenant_id": user.tenant_id,
        "email": user.email,
        "name": user.name,
    })

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "username": user.username,
            "role": user.role,
            "tenant_id": user.tenant_id,
            "email": user.email,
            "name": user.name,
        },
    }

