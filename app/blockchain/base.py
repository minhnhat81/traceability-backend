# app/blockchain/base.py
from typing import Any, Dict
import abc


class BlockchainAdapter(abc.ABC):
    """
    Interface cơ bản cho các adapter blockchain (Polygon, Fabric, v.v.)
    """

    @abc.abstractmethod
    async def anchor_batch(self, bundle_id: str, batch_hash: str, meta: Dict[str, Any]) -> Dict[str, Any]:
        """
        Đưa hash của batch lên blockchain.
        """
        raise NotImplementedError
