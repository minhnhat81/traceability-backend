from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class BlockchainConfigBase(BaseModel):
    pass

class BlockchainConfigCreate(BlockchainConfigBase):
    tenant_id: Optional[int] = None
    fabric: Optional[dict] = None
    polygon: Optional[dict] = None
    active: Optional[bool] = None

class BlockchainConfigOut(BlockchainConfigBase):
    id: int
    tenant_id: Optional[int] = None
    fabric: Optional[dict] = None
    polygon: Optional[dict] = None
    active: Optional[bool] = None
