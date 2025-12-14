# app/core/db.py
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from app.core.config import settings

# ===================================
# ⚙️ Kết nối database (async)
# ===================================
DATABASE_URL = settings.DATABASE_URL
if not DATABASE_URL.startswith("postgresql+asyncpg://"):
    DATABASE_URL = DATABASE_URL.replace(
        "postgresql://", "postgresql+asyncpg://"
    )

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    future=True,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

Base = declarative_base()

# ===================================
# ✅ Dependency chuẩn FastAPI
# ===================================
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

# ✅ ALIAS để không vỡ code cũ
get_async_session = get_db

# ✅ Alias cho code sync cũ (bạn đang dùng trong audit_mw)
SessionLocal = AsyncSessionLocal
