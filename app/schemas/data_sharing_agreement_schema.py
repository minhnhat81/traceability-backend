from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class DataSharingAgreementBase(BaseModel):
    pass

class DataSharingAgreementCreate(DataSharingAgreementBase):
    tenant_id: Optional[int] = None
    partner: Optional[str] = None
    scope: Optional[dict] = None
    terms: Optional[dict] = None

class DataSharingAgreementOut(DataSharingAgreementBase):
    id: int
    tenant_id: Optional[int] = None
    partner: Optional[str] = None
    scope: Optional[dict] = None
    terms: Optional[dict] = None
