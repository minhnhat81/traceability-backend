
from alembic import op
import sqlalchemy as sa

revision = '0005_user_passwords'
down_revision = '0004_dpp_templates'
branch_labels = None
depends_on = None

def upgrade():
    try:
        op.add_column('users', sa.Column('password_hash', sa.String(255)))
    except Exception:
        pass

def downgrade():
    try:
        op.drop_column('users', 'password_hash')
    except Exception:
        pass
