from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class CredentialBase(BaseModel):
    pass

class CredentialCreate(CredentialBase):
    tenant_id: Optional[int] = None
    subject: Optional[str] = None
    type: Optional[str] = None
    jws: Optional[str] = None
    status: Optional[str] = None

class CredentialOut(CredentialBase):
    id: int
    tenant_id: Optional[int] = None
    subject: Optional[str] = None
    type: Optional[str] = None
    jws: Optional[str] = None
    status: Optional[str] = None
