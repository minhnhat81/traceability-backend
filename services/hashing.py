
import hashlib, math
from typing import List

def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def merkle_root_hex(leaves: List[str]) -> str:
    # leaves are hex strings
    if not leaves:
        return sha256_hex(b"")
    layer = [bytes.fromhex(x) for x in leaves]
    if len(layer)==1:
        return layer[0].hex()
    while len(layer) > 1:
        nxt = []
        for i in range(0, len(layer), 2):
            left = layer[i]
            right = layer[i+1] if i+1 < len(layer) else left
            nxt.append(hashlib.sha256(left+right).digest())
        layer = nxt
    return layer[0].hex()
