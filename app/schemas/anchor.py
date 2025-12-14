from typing import List, Optional, Literal, Dict, Any
from pydantic import BaseModel, Field

Network = Literal["polygon", "fabric", "both"]

class AnchorBatchIn(BaseModel):
    doc_bundle_id: str = Field(..., alias="docBundleId")
    network: Network = Field("polygon")
    private_key: Optional[str] = None

class AnchorLeaf(BaseModel):
    type: Literal["doc", "epcis"]
    id: str
    hash_hex: str

class AnchorBatchOut(BaseModel):
    ok: bool
    bundle_id: str
    network: str
    batch_hash: str
    leaves: List[AnchorLeaf]
    tx_hash: Optional[str] = None
    block_number: Optional[int] = None
    fabric_tx_id: Optional[str] = None
    anchored_at: Optional[str] = None
    status: Optional[str] = None
    extra: Dict[str, Any] = {}
