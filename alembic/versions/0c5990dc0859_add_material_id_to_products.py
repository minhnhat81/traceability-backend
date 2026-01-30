"""add material_id to products

Revision ID: 0c5990dc0859
Revises: xxxx
Create Date: 2026-01-30 07:16:11.554566

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0c5990dc0859'
down_revision: Union[str, Sequence[str], None] = 'xxxx'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.add_column(
        "products",
        sa.Column("material_id", sa.Integer(), nullable=True)
    )

def downgrade():
    op.drop_column("products", "material_id")

