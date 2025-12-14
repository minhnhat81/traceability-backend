from pydantic import BaseModel, validator
from typing import Optional, Any
import json

class DppTemplateBase(BaseModel):
    name: str
    template_name: Optional[str] = None
    tier: Optional[str] = None
    description: Optional[str] = None
    schema: Optional[Any] = None
    static_data: Optional[Any] = None
    dynamic_data: Optional[Any] = None
    is_active: Optional[bool] = True

    # ✅ Cho phép frontend gửi string JSON
    @validator("schema", "static_data", "dynamic_data", pre=True)
    def parse_json(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except Exception:
                raise ValueError("Invalid JSON format")
        return v


class DppTemplateCreate(DppTemplateBase):
    pass


class DppTemplateUpdate(DppTemplateBase):
    pass


class DppTemplateOut(DppTemplateBase):
    id: int
    tenant_id: int

    class Config:
        orm_mode = True
