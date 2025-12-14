"""Seed default RBAC roles, scopes, and permissions"""

from alembic import op
import sqlalchemy as sa

# Revision identifiers
revision = "20251028_seed_default_rbac_roles_scopes"
down_revision = None   # hoặc thay revision cha gần nhất
branch_labels = None
depends_on = None


def upgrade():
    # 1️⃣ Insert default roles (cho tất cả tenants hiện có)
    op.execute("""
        INSERT INTO rbac_roles (tenant_id, name, description, created_at, is_active)
        SELECT t.id, r.name, r.description, NOW(), TRUE
        FROM tenants t
        CROSS JOIN (
            VALUES
              ('superadmin', 'System-wide administrator role'),
              ('admin',      'Tenant administrator role'),
              ('data_staff', 'Data operator within tenant'),
              ('supplier',   'Supplier user role')
        ) AS r(name, description)
        ON CONFLICT (tenant_id, name) DO NOTHING;
    """)

    # 2️⃣ Insert default scopes
    op.execute("""
        INSERT INTO rbac_scopes (tenant_id, resource, action, "constraint", id)
        SELECT t.id, s.resource, s.action, s.constraint::jsonb, nextval('rbac_scopes_id_seq')
        FROM tenants t
        CROSS JOIN (
            VALUES
              ('*','*','{}'),
              ('products','read','{"tenant_id":"${tenant_id}"}'),
              ('products','create','{"tenant_id":"${tenant_id}"}'),
              ('products','update','{"tenant_id":"${tenant_id}"}'),
              ('products','delete','{"tenant_id":"${tenant_id}"}'),
              ('batches','read','{"tenant_id":"${tenant_id}"}'),
              ('batches','create','{"tenant_id":"${tenant_id}"}'),
              ('batches','update','{"tenant_id":"${tenant_id}"}'),
              ('batches','delete','{"tenant_id":"${tenant_id}"}')
        ) AS s(resource, action, constraint)
        ON CONFLICT DO NOTHING;
    """)

    # 3️⃣ Insert permissions (role → scope mapping)
    # Lưu ý: rbac_permissions không có scope_id, nên ta ghi theo pattern "code"
    # => ta tạo code định danh resource.action để map với roles.
    op.execute("""
        INSERT INTO rbac_permissions (tenant_id, role_id, name, code)
        SELECT t.id, r.id, p.name, p.code
        FROM tenants t
        JOIN rbac_roles r ON r.tenant_id = t.id
        CROSS JOIN (
            VALUES
              ('superadmin_all','*.*'),
              ('admin_products_read','products.read'),
              ('admin_products_create','products.create'),
              ('admin_products_update','products.update'),
              ('admin_products_delete','products.delete'),
              ('admin_batches_read','batches.read'),
              ('admin_batches_create','batches.create'),
              ('admin_batches_update','batches.update'),
              ('admin_batches_delete','batches.delete'),
              ('data_staff_batches_read','batches.read'),
              ('data_staff_batches_create','batches.create'),
              ('data_staff_products_read','products.read'),
              ('supplier_batches_read','batches.read'),
              ('supplier_batches_create','batches.create')
        ) AS p(name, code)
        WHERE
            (r.name='superadmin' AND p.code='*.*')
            OR (r.name='admin' AND p.code LIKE 'admin_%')
            OR (r.name='data_staff' AND p.code LIKE 'data_staff_%')
            OR (r.name='supplier' AND p.code LIKE 'supplier_%')
        ON CONFLICT (role_id, code) DO NOTHING;
    """)

    # 4️⃣ Create helpful indexes
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_rbac_roles_name_tenant
            ON rbac_roles(tenant_id, name);
        CREATE INDEX IF NOT EXISTS idx_rbac_permissions_role_code
            ON rbac_permissions(role_id, code);
        CREATE INDEX IF NOT EXISTS idx_rbac_scopes_resource_action
            ON rbac_scopes(resource, action);
        CREATE INDEX IF NOT EXISTS idx_rbac_role_bindings_user_role
            ON rbac_role_bindings(user_id, role_id);
    """)


def downgrade():
    op.execute("""
        DELETE FROM rbac_permissions WHERE code IN (
            '*.*','products.read','products.create','products.update','products.delete',
            'batches.read','batches.create','batches.update','batches.delete'
        );
        DELETE FROM rbac_scopes WHERE resource IN ('*','products','batches');
        DELETE FROM rbac_roles WHERE name IN ('superadmin','admin','data_staff','supplier');
    """)
