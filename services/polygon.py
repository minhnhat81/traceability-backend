
import json, pathlib
from web3 import Web3
from app.core.config import settings

def get_w3():
    if not settings.POLYGON["rpc"]:
        return None
    return Web3(Web3.HTTPProvider(settings.POLYGON["rpc"]))

def get_contract():
    w3 = get_w3()
    if not w3: return None, None
    addr = settings.POLYGON["contract_address"]
    abi_path = settings.POLYGON["abi_path"]
    if not addr or not abi_path or not pathlib.Path(abi_path).exists():
        return w3, None
    abi = json.loads(pathlib.Path(abi_path).read_text())
    ctr = w3.eth.contract(address=Web3.to_checksum_address(addr), abi=abi)
    return w3, ctr

def eth_call(fn: str, *args):
    w3, ctr = get_contract()
    if not w3 or not ctr:
        return {"ok": False, "error": "RPC/Contract/ABI not configured"}
    try:
        fn_ref = getattr(ctr.functions, fn)
        res = fn_ref(*args).call()
        return {"ok": True, "result": Web3.to_json(res)}
    except Exception as e:
        return {"ok": False, "error": str(e)}
