# app/core/db.py
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import declarative_base
from app.core.config import settings
from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
import ssl

raw_url = settings.DATABASE_URL

# 1️⃣ Chuẩn hóa scheme
if raw_url.startswith("postgres://"):
    raw_url = raw_url.replace("postgres://", "postgresql+asyncpg://")
elif raw_url.startswith("postgresql://"):
    raw_url = raw_url.replace("postgresql://", "postgresql+asyncpg://")

# 2️⃣ REMOVE sslmode khỏi query
parsed = urlparse(raw_url)
query = parse_qs(parsed.query)
query.pop("sslmode", None)
DATABASE_URL = urlunparse(parsed._replace(query=urlencode(query, doseq=True)))

# 3️⃣ Tạo SSLContext ĐÚNG cho asyncpg
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

# 4️⃣ Engine
engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    connect_args={
        "ssl": ssl_context   # ✅ CHÍNH DÒNG NÀY
    },
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
