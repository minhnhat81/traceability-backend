from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0008_blockchain_configs_polygon_subs'
down_revision = '0007_polygon_rbac_ui'
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    print("=== START MIGRATION 0008 ===")

    try:
        print("Creating table blockchain_configs ...")
        conn.execute(sa.text("""
            CREATE TABLE IF NOT EXISTS blockchain_configs (
                id SERIAL PRIMARY KEY,
                tenant_id INTEGER REFERENCES tenants(id),
                kind VARCHAR(32),
                name VARCHAR(128),
                config JSONB,
                created_at TIMESTAMP DEFAULT now()
            );
        """))
        print("✅ blockchain_configs created successfully.")
    except Exception as e:
        print("❌ ERROR creating blockchain_configs:", e)
        raise

    try:
        print("Creating table polygon_subscriptions ...")
        conn.execute(sa.text("""
            CREATE TABLE IF NOT EXISTS polygon_subscriptions (
                id SERIAL PRIMARY KEY,
                tenant_id INTEGER REFERENCES tenants(id),
                abi_id INTEGER REFERENCES polygon_abis(id),
                event_name VARCHAR(128),
                enabled BOOLEAN DEFAULT TRUE,
                meta JSONB
            );
        """))
        print("✅ polygon_subscriptions created successfully.")
    except Exception as e:
        print("❌ ERROR creating polygon_subscriptions:", e)
        raise

    print("=== END MIGRATION 0008 ===")
