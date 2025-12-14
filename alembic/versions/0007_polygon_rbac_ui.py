from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy import inspect

revision = '0007_polygon_rbac_ui'
down_revision = '0006_customers_customs'
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    inspector = inspect(conn)

    # Chỉ tạo bảng nếu chưa tồn tại
    if 'polygon_abis' not in inspector.get_table_names():
        op.create_table(
            'polygon_abis',
            sa.Column('id', sa.Integer, primary_key=True),
            sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
            sa.Column('name', sa.String(255)),
            sa.Column('network', sa.String(64)),
            sa.Column('rpc_url', sa.String(512)),
            sa.Column('address', sa.String(128)),
            sa.Column('abi', JSONB),
            sa.Column('meta', JSONB)
        )


def downgrade():
    conn = op.get_bind()
    inspector = inspect(conn)
    if 'polygon_abis' in inspector.get_table_names():
        op.drop_table('polygon_abis')
