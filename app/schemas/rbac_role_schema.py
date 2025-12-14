from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class RbacRoleBase(BaseModel):
    pass

class RbacRoleCreate(RbacRoleBase):
    tenant_id: Optional[int] = None
    name: str
    description: Optional[str] = None

class RbacRoleOut(RbacRoleBase):
    id: int
    tenant_id: Optional[int] = None
    name: str
    description: Optional[str] = None
