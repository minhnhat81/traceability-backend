import os
import logging
from logging.config import fileConfig
from sqlalchemy import create_engine, pool, text
from alembic import context
from alembic import op as _op

# ============================================================
# Monkeypatch: Bỏ qua lỗi trùng bảng / index / cột version_num
# ============================================================

def _ensure_alembic_version_length(bind):
    """Đảm bảo cột version_num đủ dài để chứa revision dài"""
    try:
        bind.execute(
            text("ALTER TABLE IF EXISTS alembic_version ALTER COLUMN version_num TYPE VARCHAR(128);")
        )
        print("✅  Alembic version_num column length ensured to 128 chars.")
    except Exception as e:
        print(f"⚠️  Skipping version_num length alter: {e}")

# --- Kiểm tra bảng tồn tại ---
def _table_exists(bind, schema, name):
    result = bind.execute(
        text("SELECT to_regclass(:fqn)"), {"fqn": f"{schema}.{name}"}
    ).scalar()
    return result is not None

def _create_table_safe(*args, **kw):
    """Tạo bảng an toàn: bỏ qua nếu đã tồn tại"""
    bind = _op.get_bind()
    schema = kw.get("schema") or "public"
    name = args[0] if args else kw.get("name")
    if _table_exists(bind, schema, name):
        print(f"??  Table {schema}.{name} already exists ? skipping")
        return
    return _op._orig_create_table(*args, **kw)

# --- Kiểm tra index tồn tại ---
def _index_exists(bind, schema, name):
    result = bind.execute(
        text("SELECT to_regclass(:fqn)"), {"fqn": f"{schema}.{name}"}
    ).scalar()
    return result is not None

def _create_index_safe(name, table_name, *cols, **kw):
    """Tạo index an toàn: bỏ qua nếu đã tồn tại"""
    bind = _op.get_bind()
    schema = kw.get("schema") or "public"
    if _index_exists(bind, schema, name):
        print(f"??  Index {schema}.{name} already exists ? skipping")
        return
    return _op._orig_create_index(name, table_name, *cols, **kw)

# --- Áp dụng monkeypatch ---
if not hasattr(_op, "_orig_create_table"):
    _op._orig_create_table = _op.create_table
    _op.create_table = _create_table_safe

if not hasattr(_op, "_orig_create_index"):
    _op._orig_create_index = _op.create_index
    _op.create_index = _create_index_safe

# ============================================================
# Alembic configuration setup
# ============================================================

config = context.config

if config.config_file_name:
    try:
        fileConfig(config.config_file_name)
    except Exception as e:
        print(f"[Alembic Warning] Logging config failed: {e}")
        logging.basicConfig(level=logging.INFO)

logger = logging.getLogger("alembic.env")

# Nếu bạn có Base từ ORM (ví dụ app.db.base import Base)
# from app.db.base import Base
target_metadata = None  # Base.metadata nếu có

# Lấy URL DB (sync)
DB_URL = os.getenv(
    "SYNC_DATABASE_URL",
    config.get_main_option("sqlalchemy.url", "postgresql+psycopg2://trace:trace@db:5432/trace_unified")
)

# ============================================================
# Migration chế độ offline
# ============================================================
def run_migrations_offline():
    """Chạy migration không cần DB connection"""
    context.configure(
        url=DB_URL,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

# ============================================================
# Migration chế độ online
# ============================================================
def run_migrations_online():
    """Chạy migration có DB connection"""
    connectable = create_engine(DB_URL, poolclass=pool.NullPool)

    with connectable.connect() as connection:
        # Đảm bảo cột version_num đủ dài
        _ensure_alembic_version_length(connection)

        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()
        connection.commit()

# ============================================================
# Entry point
# ============================================================
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
