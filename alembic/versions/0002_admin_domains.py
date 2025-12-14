from alembic import op
import sqlalchemy as sa

revision = "0002_admin_domains"
down_revision = "0001_init"
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        "suppliers",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("code", sa.String(length=64), unique=True, nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("country", sa.String(length=64)),
        sa.Column("contact_email", sa.String(length=255)),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_suppliers_code", "suppliers", ["code"], unique=True)

    op.create_table(
        "customers",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("code", sa.String(length=64), unique=True, nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("country", sa.String(length=64)),
        sa.Column("contact_email", sa.String(length=255)),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_customers_code", "customers", ["code"], unique=True)

    op.create_table(
        "brands",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.String(length=128), unique=True, nullable=False),
        sa.Column("owner", sa.String(length=128)),
        sa.Column("website", sa.String(length=255)),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_brands_name", "brands", ["name"], unique=True)

    op.create_table(
        "users",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("username", sa.String(length=64), unique=True, nullable=False),
        sa.Column("full_name", sa.String(length=128)),
        sa.Column("email", sa.String(length=255)),
        sa.Column("role", sa.String(length=32)),
        sa.Column("created_at", sa.DateTime, server_default=sa.text("NOW()")),
    )
    op.create_index("ix_users_username", "users", ["username"], unique=True)

def downgrade():
    op.drop_index("ix_users_username", table_name="users")
    op.drop_table("users")
    op.drop_index("ix_brands_name", table_name="brands")
    op.drop_table("brands")
    op.drop_index("ix_customers_code", table_name="customers")
    op.drop_table("customers")
    op.drop_index("ix_suppliers_code", table_name="suppliers")
    op.drop_table("suppliers")
