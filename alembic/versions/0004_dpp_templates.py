
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0004_dpp_templates'
down_revision = '0003_emissions'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('dpp_templates',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('name', sa.String(255)),
        sa.Column('schema', JSONB),     # field definitions
        sa.Column('mapping', JSONB),    # mapping rules from DB fields
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()'))
    )

def downgrade():
    op.drop_table('dpp_templates')
