from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from .common import Orm


# ==============================
# 📦 BASE SCHEMA
# ==============================
class DppPassportBase(BaseModel):
    """Các trường thông tin cơ bản của DPP Passport (EU Phase 1)."""
    version: Optional[str] = Field(default="1.0", description="Phiên bản DPP schema")
    status: Optional[str] = Field(default="draft", description="Trạng thái: draft / verified / archived")

    # --- 16 nhóm thông tin DPP ---
    product_description: Optional[Dict[str, Any]] = None
    composition: Optional[Dict[str, Any]] = None
    supply_chain: Optional[Dict[str, Any]] = None
    transport: Optional[Dict[str, Any]] = None
    documentation: Optional[Dict[str, Any]] = None
    environmental_impact: Optional[Dict[str, Any]] = None
    social_impact: Optional[Dict[str, Any]] = None
    animal_welfare: Optional[Dict[str, Any]] = None
    circularity: Optional[Dict[str, Any]] = None
    health_safety: Optional[Dict[str, Any]] = None
    brand_info: Optional[Dict[str, Any]] = None
    digital_identity: Optional[Dict[str, Any]] = None
    quantity_info: Optional[Dict[str, Any]] = None
    cost_info: Optional[Dict[str, Any]] = None
    use_phase: Optional[Dict[str, Any]] = None
    end_of_life: Optional[Dict[str, Any]] = None

    # --- Liên kết ---
    linked_epcis: Optional[Dict[str, Any]] = None
    linked_blockchain: Optional[Dict[str, Any]] = None


# ==============================
# 🏗️ CREATE / UPDATE SCHEMAS
# ==============================
class DppPassportCreate(DppPassportBase):
    """Schema dùng khi tạo mới passport."""
    tenant_id: Optional[int] = None
    batch_id: Optional[int] = None


class DppPassportUpdate(DppPassportBase):
    """Schema dùng để cập nhật passport."""
    status: Optional[str] = None
    linked_epcis: Optional[Dict[str, Any]] = None
    linked_blockchain: Optional[Dict[str, Any]] = None


# ==============================
# 📤 OUTPUT SCHEMA
# ==============================
class DppPassportOut(Orm):
    id: int
    tenant_id: Optional[int] = None
    batch_id: Optional[int] = None
    version: Optional[str] = "1.0"
    status: Optional[str] = "draft"

    # --- 16 nhóm thông tin DPP ---
    product_description: Optional[Dict[str, Any]] = None
    composition: Optional[Dict[str, Any]] = None
    supply_chain: Optional[Dict[str, Any]] = None
    transport: Optional[Dict[str, Any]] = None
    documentation: Optional[Dict[str, Any]] = None
    environmental_impact: Optional[Dict[str, Any]] = None
    social_impact: Optional[Dict[str, Any]] = None
    animal_welfare: Optional[Dict[str, Any]] = None
    circularity: Optional[Dict[str, Any]] = None
    health_safety: Optional[Dict[str, Any]] = None
    brand_info: Optional[Dict[str, Any]] = None
    digital_identity: Optional[Dict[str, Any]] = None
    quantity_info: Optional[Dict[str, Any]] = None
    cost_info: Optional[Dict[str, Any]] = None
    use_phase: Optional[Dict[str, Any]] = None
    end_of_life: Optional[Dict[str, Any]] = None

    # --- Liên kết ---
    linked_epcis: Optional[Dict[str, Any]] = None
    linked_blockchain: Optional[Dict[str, Any]] = None

    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True
