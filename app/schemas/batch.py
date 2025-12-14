from datetime import date, datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel
from .common import Orm


# =====================================
# BASE
# =====================================

class BatchBase(BaseModel):
    code: str
    product_code: str
    mfg_date: Optional[date] = None
    country: Optional[str] = None
    status: Optional[str] = "active"
    quantity: Optional[float] = None
    material_type: Optional[str] = None
    description: Optional[str] = None
    origin_farm_id: Optional[int] = None
    certificates: Optional[Dict[str, Any]] = None
    origin: Optional[Dict[str, Any]] = None

    # 🔥 Thêm 4 cấp batch code
    farm_batch_code: Optional[str] = None
    supplier_batch_code: Optional[str] = None
    manufacturer_batch_code: Optional[str] = None
    brand_batch_code: Optional[str] = None

    # 🔗 Tham chiếu batch cha
    farm_batch_id: Optional[int] = None
    supplier_batch_id: Optional[int] = None
    manufacturer_batch_id: Optional[int] = None
    brand_batch_id: Optional[int] = None


# =====================================
# CREATE / UPDATE
# =====================================

class BatchCreate(BatchBase):
    tenant_id: Optional[int] = None
    parent_batch_id: Optional[int] = None


class BatchUpdate(BatchBase):
    """Schema dùng để cập nhật batch."""
    status: Optional[str] = None
    quantity: Optional[float] = None
    description: Optional[str] = None


# =====================================
# OUTPUT / ORM
# =====================================

class BatchOut(Orm):
    id: int
    tenant_id: Optional[int]
    code: str
    product_code: str
    mfg_date: Optional[date] = None
    country: Optional[str] = None
    status: Optional[str] = None
    quantity: Optional[float] = None
    material_type: Optional[str] = None
    description: Optional[str] = None
    origin_farm_id: Optional[int] = None
    certificates: Optional[Dict[str, Any]] = None
    origin: Optional[Dict[str, Any]] = None
    dpp_id: Optional[int] = None
    blockchain_tx_hash: Optional[str] = None
    created_at: datetime

    # 🔥 Chain batch codes
    farm_batch_code: Optional[str] = None
    supplier_batch_code: Optional[str] = None
    manufacturer_batch_code: Optional[str] = None
    brand_batch_code: Optional[str] = None

    # 🔗 Chain relationships
    farm_batch_id: Optional[int] = None
    supplier_batch_id: Optional[int] = None
    manufacturer_batch_id: Optional[int] = None
    brand_batch_id: Optional[int] = None

    class Config:
        orm_mode = True
