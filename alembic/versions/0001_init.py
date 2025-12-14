from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = "0001_init"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        "products",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("code", sa.String(64), unique=True, nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("category", sa.String(128)),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("NOW()")),
    )
    op.create_table(
        "batches",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("code", sa.String(64), unique=True, nullable=False),
        sa.Column("product_code", sa.String(64), nullable=False),
        sa.Column("mfg_date", sa.Date()),
        sa.Column("country", sa.String(64)),
    )
    op.create_table(
        "events",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("batch_code", sa.String(64), nullable=False),
        sa.Column("product_code", sa.String(64), nullable=False),
        sa.Column("event_time", sa.DateTime, server_default=sa.text("NOW()")),
        sa.Column("biz_step", sa.String(128)),
        sa.Column("disposition", sa.String(128)),
        sa.Column("data", JSONB),
    )
    op.create_table(
        "fabric_events",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("tx_id", sa.String(128)),
        sa.Column("block_number", sa.BigInteger),
        sa.Column("chaincode_id", sa.String(128)),
        sa.Column("event_name", sa.String(128)),
        sa.Column("payload", JSONB),
        sa.Column("status", sa.String(32), server_default=sa.text("'RECEIVED'")),
        sa.Column("ts", sa.DateTime, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_fabric_events_block_tx", "fabric_events", ["block_number", "tx_id"])
    op.create_table(
        "polygon_anchors",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("tx_hash", sa.String(100)),
        sa.Column("anchor_type", sa.String(50)),
        sa.Column("ref_id", sa.String(64)),
        sa.Column("status", sa.String(32)),
        sa.Column("ts", sa.DateTime, server_default=sa.text("NOW()")),
        sa.Column("meta", JSONB),
    )
    op.create_table(
        "polygon_abi",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.Text),
        sa.Column("abi", JSONB),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("NOW()")),
    )

def downgrade():
    op.drop_table("polygon_abi")
    op.drop_table("polygon_anchors")
    op.drop_index("ix_fabric_events_block_tx", table_name="fabric_events")
    op.drop_table("fabric_events")
    op.drop_table("events")
    op.drop_table("batches")
    op.drop_table("products")
