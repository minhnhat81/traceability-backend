from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class ComplianceResultBase(BaseModel):
    pass

class ComplianceResultCreate(ComplianceResultBase):
    tenant_id: Optional[int] = None
    batch_code: Optional[str] = None
    scheme: Optional[str] = None
    pass_flag: Optional[bool] = None
    details: Optional[dict] = None

class ComplianceResultOut(ComplianceResultBase):
    id: int
    tenant_id: Optional[int] = None
    batch_code: Optional[str] = None
    scheme: Optional[str] = None
    pass_flag: Optional[bool] = None
    details: Optional[dict] = None
