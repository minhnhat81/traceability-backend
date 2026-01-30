from alembic import op
import sqlalchemy as sa


revision = "xxxx"
down_revision = "7ec1ba5c4b4c"
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table("products") as batch:
        batch.add_column(
            sa.Column("tenant_id", sa.Integer(), nullable=True)
        )
        batch.create_foreign_key(
            "fk_products_tenant_id",
            "tenants",
            ["tenant_id"],
            ["id"],
        )


def downgrade():
    with op.batch_alter_table("products") as batch:
        batch.drop_constraint("fk_products_tenant_id", type_="foreignkey")
        batch.drop_column("tenant_id")
