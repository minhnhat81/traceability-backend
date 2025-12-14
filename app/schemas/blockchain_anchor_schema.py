from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class BlockchainAnchorBase(BaseModel):
    pass

class BlockchainAnchorCreate(BlockchainAnchorBase):
    tenant_id: Optional[int] = None
    anchor_type: Optional[str] = None
    ref: Optional[str] = None
    tx_hash: Optional[str] = None
    network: Optional[str] = None
    meta: Optional[dict] = None

class BlockchainAnchorOut(BlockchainAnchorBase):
    id: int
    tenant_id: Optional[int] = None
    anchor_type: Optional[str] = None
    ref: Optional[str] = None
    tx_hash: Optional[str] = None
    network: Optional[str] = None
    meta: Optional[dict] = None
