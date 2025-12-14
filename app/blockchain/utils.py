# app/blockchain/utils.py
import json
import hashlib
from datetime import datetime, timezone


def canonical_json(data) -> str:
    """
    Chuyển object Python (dict/list) thành JSON chuẩn, stable cho hashing.
    """
    return json.dumps(data, sort_keys=True, separators=(",", ":"))


def sha256_hex(data: str | bytes) -> str:
    """
    Hash SHA256 và trả về hex string.
    """
    if isinstance(data, str):
        data = data.encode("utf-8")
    return hashlib.sha256(data).hexdigest()


def canonical_hash(obj) -> str:
    """
    Hash SHA256 từ object JSON (dict hoặc list).
    """
    return sha256_hex(canonical_json(obj))


def utc_now_iso() -> str:
    """
    Lấy timestamp ISO UTC.
    """
    return datetime.now(timezone.utc).isoformat()


def short_tx_hash(batch_code: str, root_hash: str) -> str:
    """
    Sinh tx_hash giả lập (dùng khi không gửi tx thật lên chain).
    """
    return "0x" + sha256_hex(f"{batch_code}:{root_hash}")[:64]


def merkle_root_hex(hashes: list[str]) -> str:
    """
    Tính toán Merkle Root từ danh sách các hash hex (SHA256).
    Trả về giá trị Merkle Root dạng hex string.

    Nếu số lượng node lẻ -> nhân đôi node cuối.
    """
    if not hashes:
        raise ValueError("Danh sách hash rỗng.")

    # Chuyển tất cả hash về bytes
    nodes = [bytes.fromhex(h) for h in hashes]

    # Tính Merkle tree
    while len(nodes) > 1:
        new_level = []
        for i in range(0, len(nodes), 2):
            left = nodes[i]
            right = nodes[i + 1] if i + 1 < len(nodes) else nodes[i]
            combined = hashlib.sha256(left + right).digest()
            new_level.append(combined)
        nodes = new_level

    return nodes[0].hex()
