from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class PolygonLogBase(BaseModel):
    pass

class PolygonLogCreate(PolygonLogBase):
    tx_hash: Optional[str] = None
    method: Optional[str] = None
    params: Optional[dict] = None
    result: Optional[dict] = None

class PolygonLogOut(PolygonLogBase):
    id: int
    tx_hash: Optional[str] = None
    method: Optional[str] = None
    params: Optional[dict] = None
    result: Optional[dict] = None
