
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0006_customers_customs'
down_revision = '0005_user_passwords'
branch_labels = None
depends_on = None

def upgrade():
    try:
        op.create_table('customers',
            sa.Column('id', sa.Integer, primary_key=True),
            sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
            sa.Column('code', sa.String(64), unique=True, index=True),
            sa.Column('name', sa.String(255)),
            sa.Column('country', sa.String(64)),
            sa.Column('contact', JSONB),
            sa.Column('meta', JSONB)
        )
    except Exception:
        pass
    try:
        op.create_table('customs_declarations',
            sa.Column('id', sa.Integer, primary_key=True),
            sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
            sa.Column('batch_code', sa.String(128)),
            sa.Column('hs_code', sa.String(64)),
            sa.Column('destination_country', sa.String(64)),
            sa.Column('files', JSONB),
            sa.Column('status', sa.String(32), server_default='draft'),
            sa.Column('meta', JSONB)
        )
    except Exception:
        pass

def downgrade():
    for t in ['customs_declarations','customers']:
        try: op.drop_table(t)
        except Exception: pass
