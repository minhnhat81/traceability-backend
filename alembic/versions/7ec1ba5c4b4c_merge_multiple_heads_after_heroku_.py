"""merge multiple heads after heroku migration

Revision ID: 7ec1ba5c4b4c
Revises: 0002_admin_domains, 0003_emissions_dpp_templates, 0008_blockchain_configs_polygon_subs
Create Date: 2026-01-29 17:24:21.903461

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7ec1ba5c4b4c'
down_revision: Union[str, Sequence[str], None] = ('0002_admin_domains', '0003_emissions_dpp_templates', '0008_blockchain_configs_polygon_subs')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
