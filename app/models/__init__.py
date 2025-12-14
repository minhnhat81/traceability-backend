from sqlalchemy.ext.declarative import declarative_base

# ==============================
# Base model
# ==============================
Base = declarative_base()

# ==============================
# Import tất cả các model ORM
# ==============================

from .tenant import *
from .user import *
from .supplier import *
from .brand import *
from .customer import *
from .product import *
from .batch import Batch
from .event import *
from .fabric_event import *
from .polygon_anchor import *
from .polygon_abi import *
from .polygon_subscription import *
from .polygon_log import *

from .configs_blockchain import *
from .blockchain_anchor import BlockchainAnchor 

from .domain import *
from .portal import *
from .emission import *
from .dpp_template import *
from .dpp_passport import *
from .customs import *
from .document import *
from .credential import *
from .data_sharing_agreement import *
from .compliance_result import *

from .audit_log import *
from .sensor_event import *
from .epcis_event import *
from .farm import Farm
# RBAC
from .rbac_role import *
from .rbac_permission import *
from .rbac_scope import *
from .rbac_role_binding import *

# UI & misc
from .ui_menu import *

# ==============================
# Ghi chú:
# Việc import toàn bộ model tại đây giúp SQLAlchemy nhận diện
# tất cả các bảng và ForeignKey trước khi Base.metadata.create_all()
# được gọi (tránh lỗi "NoReferencedTableError" và "InvalidRequestError")
# ==============================
