from sqlalchemy import create_engine
from app.models import Base

# ⚠️ Dùng psycopg2 (đồng bộ), KHÔNG dùng asyncpg
DATABASE_URL = "postgresql+psycopg2://trace:trace@trace-db:5432/trace_unified"

def init_db():
    print("🚀 Connecting to database...")
    engine = create_engine(DATABASE_URL)
    print("🧱 Creating all tables from models...")
    Base.metadata.create_all(bind=engine)
    print("✅ Done. Database schema is ready.")

if __name__ == "__main__":
    init_db()
