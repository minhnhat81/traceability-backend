from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class DocumentBase(BaseModel):
    pass

class DocumentCreate(DocumentBase):
    tenant_id: Optional[int] = None
    title: Optional[str] = None
    hash: Optional[str] = None
    path: Optional[str] = None
    meta: Optional[dict] = None

class DocumentOut(DocumentBase):
    id: int
    tenant_id: Optional[int] = None
    title: Optional[str] = None
    hash: Optional[str] = None
    path: Optional[str] = None
    meta: Optional[dict] = None
