from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class RbacRoleBindingBase(BaseModel):
    pass

class RbacRoleBindingCreate(RbacRoleBindingBase):
    tenant_id: Optional[int] = None
    user_id: Optional[int] = None
    role_id: Optional[int] = None

class RbacRoleBindingOut(RbacRoleBindingBase):
    id: int
    tenant_id: Optional[int] = None
    user_id: Optional[int] = None
    role_id: Optional[int] = None
