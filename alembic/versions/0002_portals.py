
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0002_portals'
down_revision = '0001_unified_init'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('suppliers',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('code', sa.String(64), unique=True, index=True),
        sa.Column('name', sa.String(255)),
        sa.Column('country', sa.String(64)),
        sa.Column('certifications', JSONB),
        sa.Column('meta', JSONB)
    )
    op.create_table('factories',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('supplier_id', sa.Integer, sa.ForeignKey('suppliers.id')),
        sa.Column('name', sa.String(255)),
        sa.Column('location', sa.String(255)),
        sa.Column('profile', JSONB)
    )
    op.create_table('processes',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('factory_id', sa.Integer, sa.ForeignKey('factories.id')),
        sa.Column('ptype', sa.String(32)), # spinning/weaving/dyeing/sewing
        sa.Column('line_code', sa.String(64)),
        sa.Column('capabilities', JSONB)
    )
    op.create_table('market_configs',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('evfta', JSONB),
        sa.Column('cptpp', JSONB),
        sa.Column('eu_dpp', JSONB),
        sa.Column('uflpa', JSONB),
        sa.Column('updated_at', sa.DateTime, server_default=sa.text('NOW()'))
    )

def downgrade():
    for t in ['market_configs','processes','factories','suppliers']:
        op.drop_table(t)
