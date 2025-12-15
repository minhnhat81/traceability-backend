from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse

from app.core.config import settings

raw_url = settings.DATABASE_URL

# 1️⃣ ÉP DRIVER asyncpg
if raw_url.startswith("postgres://"):
    raw_url = raw_url.replace("postgres://", "postgresql+asyncpg://")
elif raw_url.startswith("postgresql://"):
    raw_url = raw_url.replace("postgresql://", "postgresql+asyncpg://")

# 2️⃣ LOẠI BỎ TOÀN BỘ psycopg-only params
parsed = urlparse(raw_url)
query = parse_qs(parsed.query)

# ⚠️ CÁI NÀY LÀ CHÌA KHÓA
query.pop("sslmode", None)
query.pop("channel_binding", None)

DATABASE_URL = urlunparse(
    parsed._replace(query=urlencode(query, doseq=True))
)

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

# alias cho code cũ
get_async_session = get_db
SessionLocal = AsyncSessionLocal
