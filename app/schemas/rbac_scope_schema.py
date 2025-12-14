from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class RbacScopeBase(BaseModel):
    pass

class RbacScopeCreate(RbacScopeBase):
    tenant_id: Optional[int] = None
    resource: str
    action: str
    constraint: Optional[dict] = None

class RbacScopeOut(RbacScopeBase):
    id: int
    tenant_id: Optional[int] = None
    resource: str
    action: str
    constraint: Optional[dict] = None
