from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class AuditLogBase(BaseModel):
    pass

class AuditLogCreate(AuditLogBase):
    tenant_id: Optional[int] = None
    user: Optional[str] = None
    method: Optional[str] = None
    path: Optional[str] = None
    status: Optional[int] = None
    ip: Optional[str] = None
    payload: Optional[dict] = None
    created_at: Optional[datetime] = None

class AuditLogOut(AuditLogBase):
    id: int
    tenant_id: Optional[int] = None
    user: Optional[str] = None
    method: Optional[str] = None
    path: Optional[str] = None
    status: Optional[int] = None
    ip: Optional[str] = None
    payload: Optional[dict] = None
    created_at: Optional[datetime] = None
