
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0003_emissions_dpp_templates'
down_revision = '0003_emissions'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('emission_factors',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('name', sa.String(128)),
        sa.Column('scope', sa.String(8)),  # 1/2/3
        sa.Column('unit', sa.String(32)),
        sa.Column('value', sa.Float),
        sa.Column('source', sa.String(255))
    )
    op.create_table('emission_records',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('batch_code', sa.String(64), index=True),
        sa.Column('scope', sa.String(8)),
        sa.Column('amount', sa.Float),
        sa.Column('unit', sa.String(32)),
        sa.Column('factor_id', sa.Integer, sa.ForeignKey('emission_factors.id')),
        sa.Column('meta', JSONB)
    )
    op.create_table('dpp_templates',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('name', sa.String(128)),
        sa.Column('schema', JSONB),   # field definitions
        sa.Column('mapping', JSONB)   # source mapping rules
    )

def downgrade():
    for t in ['dpp_templates','emission_records','emission_factors']:
        op.drop_table(t)
