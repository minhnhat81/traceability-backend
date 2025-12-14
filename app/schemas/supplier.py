from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Any

class SupplierBase(BaseModel):
    code: str
    name: str
    country: Optional[str] = None
    contact_email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    factory_location: Optional[str] = None
    certification: Optional[Any] = Field(default=None, description="Certification JSON object")  # ✅ JSON
    user_id: Optional[int] = None

class SupplierCreate(SupplierBase):
    pass

class SupplierUpdate(SupplierBase):
    pass

class SupplierOut(SupplierBase):
    id: int
    tenant_id: Optional[int] = None

    # ⚡ Pydantic v2 config (thay cho class Config)
    model_config = ConfigDict(from_attributes=True)
