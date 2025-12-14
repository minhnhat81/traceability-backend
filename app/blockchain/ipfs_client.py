import aiohttp
import os
from typing import Tuple

PINATA_JWT = os.getenv("PINATA_JWT")  # bạn set trong .env

PINATA_UPLOAD_URL = "https://api.pinata.cloud/pinning/pinJSONToIPFS"


async def upload_json_to_ipfs(payload: dict) -> Tuple[str, str]:
    """
    Upload JSON lên IPFS, trả về (cid, gateway_url)
    """
    headers = {
        "Authorization": f"Bearer {PINATA_JWT}",
        "Content-Type": "application/json",
    }

    async with aiohttp.ClientSession() as session:
        async with session.post(PINATA_UPLOAD_URL, headers=headers, json=payload) as resp:
            data = await resp.json()
            if resp.status != 200:
                raise RuntimeError(f"Pinata error: {data}")
            cid = data["IpfsHash"]
            gateway = f"https://gateway.pinata.cloud/ipfs/{cid}"
            return cid, gateway
