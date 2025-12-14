from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class DppPassportBase(BaseModel):
    pass

class DppPassportCreate(DppPassportBase):
    tenant_id: Optional[int] = None
    product_code: Optional[str] = None
    payload: Optional[dict] = None
    version: Optional[str] = None

class DppPassportOut(DppPassportBase):
    id: int
    tenant_id: Optional[int] = None
    product_code: Optional[str] = None
    payload: Optional[dict] = None
    version: Optional[str] = None
