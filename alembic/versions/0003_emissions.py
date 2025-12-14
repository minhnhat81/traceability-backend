
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0003_emissions'
down_revision = '0002_portals'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('emissions_factors',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('name', sa.String(255)),
        sa.Column('scope', sa.Integer),
        sa.Column('factor', sa.Float),
        sa.Column('unit', sa.String(64)),
        sa.Column('source', sa.String(255)),
        sa.Column('meta', JSONB)
    )
    op.create_table('emissions_records',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('scope', sa.Integer),
        sa.Column('activity', sa.String(255)),
        sa.Column('quantity', sa.Float),
        sa.Column('unit', sa.String(64)),
        sa.Column('factor', sa.Float),
        sa.Column('period_start', sa.Date),
        sa.Column('period_end', sa.Date),
        sa.Column('meta', JSONB)
    )

def downgrade():
    for t in ['emissions_records','emissions_factors']:
        op.drop_table(t)
