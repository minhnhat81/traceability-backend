from typing import Optional, Any
from pydantic import BaseModel, Field
from datetime import datetime


class FarmBase(BaseModel):
    name: str
    code: Optional[str] = None
    gln: Optional[str] = None
    location: Optional[dict[str, Any]] = None
    size_ha: Optional[float] = None
    certification: Optional[dict[str, Any]] = None
    contact_info: Optional[dict[str, Any]] = None
    farm_type: Optional[str] = None
    status: Optional[str] = Field(default="active")
    extra_data: Optional[dict[str, Any]] = Field(default_factory=dict)


# ------------------------
# ✅ Dùng khi tạo mới
# ------------------------
class FarmCreate(FarmBase):
    pass


# ------------------------
# ✅ Dùng khi cập nhật
# ------------------------
class FarmUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    gln: Optional[str] = None
    location: Optional[dict[str, Any]] = None
    size_ha: Optional[float] = None
    certification: Optional[dict[str, Any]] = None
    contact_info: Optional[dict[str, Any]] = None
    farm_type: Optional[str] = None
    status: Optional[str] = None
    extra_data: Optional[dict[str, Any]] = None


# ------------------------
# ✅ Dùng khi đọc dữ liệu
# ------------------------
class FarmRead(FarmBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True
