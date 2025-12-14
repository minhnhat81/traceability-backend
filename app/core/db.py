# app/core/db.py
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from app.core.config import settings
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse

raw_url = settings.DATABASE_URL

# 1️⃣ Chuẩn hóa scheme cho asyncpg
if raw_url.startswith("postgres://"):
    raw_url = raw_url.replace("postgres://", "postgresql+asyncpg://")
elif raw_url.startswith("postgresql://"):
    raw_url = raw_url.replace("postgresql://", "postgresql+asyncpg://")

# 2️⃣ LOẠI BỎ sslmode khỏi query string (🔥 DÒNG QUYẾT ĐỊNH)
parsed = urlparse(raw_url)
query = parse_qs(parsed.query)
query.pop("sslmode", None)   # ❌ asyncpg không hỗ trợ sslmode

clean_query = urlencode(query, doseq=True)
DATABASE_URL = urlunparse(parsed._replace(query=clean_query))

# 3️⃣ Tạo engine với SSL đúng chuẩn asyncpg
engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    future=True,
    pool_pre_ping=True,
    connect_args={
        "ssl": "require"
    },
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

get_async_session = get_db
SessionLocal = AsyncSessionLocal
