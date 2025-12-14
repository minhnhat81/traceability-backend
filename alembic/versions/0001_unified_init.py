
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '0001_unified_init'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('tenants',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('code', sa.String(64), unique=True, index=True),
        sa.Column('name', sa.String(255))
    )
    op.create_table('users',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('email', sa.String(255), unique=True, index=True),
        sa.Column('name', sa.String(255)),
        sa.Column('role', sa.String(64))
    )
    op.create_table('roles',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('name', sa.String(64)),
        sa.Column('description', sa.Text)
    )
    op.create_table('scopes',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('resource', sa.String(64)),
        sa.Column('action', sa.String(16)),
        sa.Column('constraint', JSONB)
    )
    op.create_table('role_bindings',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('users.id')),
        sa.Column('role_id', sa.Integer, sa.ForeignKey('roles.id'))
    )
    op.create_table('products',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('code', sa.String(64), unique=True, index=True),
        sa.Column('name', sa.String(255)),
        sa.Column('category', sa.String(128)),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()'))
    )
    op.create_table('batches',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('code', sa.String(64), unique=True, index=True),
        sa.Column('product_code', sa.String(64), index=True),
        sa.Column('mfg_date', sa.Date()),
        sa.Column('country', sa.String(64))
    )
    op.create_table('epcis_events',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('event_type', sa.String(32)),
        sa.Column('batch_code', sa.String(64), index=True),
        sa.Column('product_code', sa.String(64), index=True),
        sa.Column('event_time', sa.DateTime),
        sa.Column('event_tz', sa.String(10)),
        sa.Column('action', sa.String(10)),
        sa.Column('biz_step', sa.String(128)),
        sa.Column('disposition', sa.String(128)),
        sa.Column('read_point', sa.String(255)),
        sa.Column('biz_location', sa.String(255)),
        sa.Column('epc_list', JSONB),
        sa.Column('biz_tx_list', JSONB),
        sa.Column('ilmd', JSONB),
        sa.Column('extensions', JSONB)
    )
    op.create_table('sensor_events',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('epcis_event_id', sa.Integer, sa.ForeignKey('epcis_events.id')),
        sa.Column('sensor_meta', JSONB),
        sa.Column('sensor_reports', JSONB)
    )
    op.create_table('documents',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('title', sa.String(255)),
        sa.Column('hash', sa.String(128)),
        sa.Column('path', sa.String(512)),
        sa.Column('meta', JSONB)
    )
    op.create_table('credentials',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('subject', sa.String(255)),
        sa.Column('type', sa.String(64)),
        sa.Column('jws', sa.Text),
        sa.Column('status', sa.String(32))
    )
    op.create_table('anchors',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('anchor_type', sa.String(64)),
        sa.Column('ref', sa.String(255)),
        sa.Column('tx_hash', sa.String(128)),
        sa.Column('network', sa.String(64)),
        sa.Column('meta', JSONB)
    )
    op.create_table('compliance_results',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('batch_code', sa.String(64)),
        sa.Column('scheme', sa.String(64)),
        sa.Column('pass_flag', sa.Boolean()),
        sa.Column('details', JSONB)
    )
    op.create_table('dpp_passports',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('product_code', sa.String(64)),
        sa.Column('payload', JSONB),
        sa.Column('version', sa.String(16))
    )
    op.create_table('data_sharing_agreements',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('partner', sa.String(255)),
        sa.Column('scope', JSONB),
        sa.Column('terms', JSONB)
    )
    op.create_table('blockchain_configs',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('fabric', JSONB),
        sa.Column('polygon', JSONB),
        sa.Column('active', sa.Boolean())
    )
    op.create_table('fabric_events',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tx_id', sa.String(128)),
        sa.Column('block_number', sa.BigInteger()),
        sa.Column('chaincode_id', sa.String(128)),
        sa.Column('event_name', sa.String(128)),
        sa.Column('payload', JSONB)
    )
    op.create_table('polygon_logs',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tx_hash', sa.String(128)),
        sa.Column('method', sa.String(128)),
        sa.Column('params', JSONB),
        sa.Column('result', JSONB)
    )
    op.create_table('audit_logs',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('tenant_id', sa.Integer, sa.ForeignKey('tenants.id')),
        sa.Column('user', sa.String(255)),
        sa.Column('method', sa.String(8)),
        sa.Column('path', sa.String(255)),
        sa.Column('status', sa.Integer),
        sa.Column('ip', sa.String(64)),
        sa.Column('payload', JSONB),
        sa.Column('created_at', sa.DateTime, server_default=sa.text('NOW()'))
    )

def downgrade():
    for t in ['audit_logs','polygon_logs','fabric_events','blockchain_configs','data_sharing_agreements','dpp_passports','compliance_results','anchors','credentials','documents','sensor_events','epcis_events','batches','products','role_bindings','scopes','roles','users','tenants']:
        op.drop_table(t)
