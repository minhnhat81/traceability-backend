
import httpx
from app.core.config import settings

async def evaluate(fcn: str, args: list[str]):
    base = settings.FABRIC["gateway_base"]
    if not base: 
        return {"ok": False, "error": "gateway_base not configured"}
    async with httpx.AsyncClient(timeout=15) as client:
        r = await client.post(f"{base}/evaluate", json={"fcn": fcn, "args": args})
        return r.json()

async def submit(fcn: str, args: list[str]):
    base = settings.FABRIC["gateway_base"]
    if not base:
        return {"ok": False, "error": "gateway_base not configured"}
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(f"{base}/submit", json={"fcn": fcn, "args": args})
        return r.json()
