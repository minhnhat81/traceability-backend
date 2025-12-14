from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class EpcisEventBase(BaseModel):
    pass

class EpcisEventCreate(EpcisEventBase):
    tenant_id: Optional[int] = None
    event_type: Optional[str] = None
    batch_code: Optional[str] = None
    product_code: Optional[str] = None
    material_name: Optional[str] = None  # 👈 Thêm vào đây
    event_time: Optional[datetime] = None
    event_tz: Optional[str] = None
    action: Optional[str] = None
    biz_step: Optional[str] = None
    disposition: Optional[str] = None
    read_point: Optional[str] = None
    biz_location: Optional[str] = None
    epc_list: Optional[dict] = None
    biz_tx_list: Optional[dict] = None
    ilmd: Optional[dict] = None
    extensions: Optional[dict] = None
    context: Optional[List[Any]] = Field(default_factory=list, alias="@context")

class EpcisEventOut(EpcisEventBase):
    id: int
    tenant_id: Optional[int] = None
    event_type: Optional[str] = None
    batch_code: Optional[str] = None
    product_code: Optional[str] = None
    event_time: Optional[datetime] = None
    event_tz: Optional[str] = None
    action: Optional[str] = None
    biz_step: Optional[str] = None
    disposition: Optional[str] = None
    read_point: Optional[str] = None
    biz_location: Optional[str] = None
    epc_list: Optional[dict] = None
    biz_tx_list: Optional[dict] = None
    ilmd: Optional[dict] = None
    extensions: Optional[dict] = None
    context: Optional[List[Any]] = Field(default_factory=list, alias="@context")
