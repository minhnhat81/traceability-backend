from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission
from app.blockchain.manager import BlockchainManager
import json

router = APIRouter(prefix="/api/configs", tags=["configs"])


# ============================================================
# 🔹 GET /api/configs/blockchain — Trả về cấu hình cuối cùng
# ============================================================
@router.get("/blockchain")
async def list_configs(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    Trả về cấu hình cuối cùng của Polygon và Fabric (nếu có).
    """
    tenant_id = user.get("tenant_id", 1)
    rows = await db.execute(
        text(
            """
            SELECT chain_name, rpc_url, contract_address, network, abi_id, config_json
            FROM configs_blockchain
            WHERE tenant_id = :t
            ORDER BY id DESC
            """
        ),
        {"t": tenant_id},
    )
    data = {"polygon": None, "fabric": None}
    for r in rows.fetchall():
        m = r._mapping
        cfg = {
            "chain_name": m["chain_name"],
            "rpc_url": m["rpc_url"],
            "contract_address": m["contract_address"],
            "network": m["network"],
            "abi_id": m["abi_id"],
            "config_json": json.loads(m["config_json"]) if isinstance(m["config_json"], str) else m["config_json"],
        }
        if (m["network"] or "").lower().startswith("polygon"):
            data["polygon"] = cfg
        elif (m["network"] or "").lower().startswith("fabric"):
            data["fabric"] = cfg
    return data


# ============================================================
# 🔹 POST /api/configs/blockchain — Lưu và ghi đè cấu hình
# ============================================================
@router.post("/blockchain")
async def save_config(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    Lưu cấu hình blockchain (Polygon / Fabric)
    -> Xóa bản cũ cùng network, chỉ giữ bản ghi cuối cùng.
    """
    if not check_permission(db, user, "configs", "create", body,
                            path="/api/configs/blockchain", method="POST"):
        raise HTTPException(403, "Permission denied")

    tenant_id = user.get("tenant_id", 1)
    chain_name = body.get("chain_name")
    network = (body.get("network") or "").lower()

    if network not in ["polygon", "fabric"]:
        raise HTTPException(400, "Invalid network name")

    # 🧹 Xóa cấu hình cũ của cùng network
    await db.execute(
        text("DELETE FROM configs_blockchain WHERE tenant_id = :t AND LOWER(network) = :n"),
        {"t": tenant_id, "n": network},
    )

    # 🔄 Chuẩn hóa config_json
    cfg_json = body.get("config_json", {})
    if not isinstance(cfg_json, dict):
        try:
            cfg_json = json.loads(cfg_json)
        except Exception:
            cfg_json = {}

    await db.execute(
        text(
            """
            INSERT INTO configs_blockchain(
                tenant_id, chain_name, rpc_url, contract_address, network, abi_id, 
                is_default, config_json, created_at, updated_at
            )
            VALUES (
                :t, :n, :r, :a, :nw, :abi, true, :cfg, NOW(), NOW()
            )
            """
        ),
        {
            "t": tenant_id,
            "n": chain_name,
            "r": body.get("rpc_url", ""),
            "a": body.get("contract_address", ""),
            "nw": network,
            "abi": body.get("abi_id", 1),
            "cfg": json.dumps(cfg_json),
        },
    )
    await db.commit()

    # 🔁 Trả về cấu hình sau khi cập nhật
    rows = await db.execute(
        text(
            """
            SELECT chain_name, rpc_url, contract_address, network, abi_id, config_json
            FROM configs_blockchain
            WHERE tenant_id = :t
            ORDER BY id DESC
            """
        ),
        {"t": tenant_id},
    )

    data = {"polygon": None, "fabric": None}
    for r in rows.fetchall():
        m = r._mapping
        cfg = {
            "chain_name": m["chain_name"],
            "rpc_url": m["rpc_url"],
            "contract_address": m["contract_address"],
            "network": m["network"],
            "abi_id": m["abi_id"],
            "config_json": json.loads(m["config_json"]) if isinstance(m["config_json"], str) else m["config_json"],
        }
        if (m["network"] or "").lower().startswith("polygon"):
            data["polygon"] = cfg
        elif (m["network"] or "").lower().startswith("fabric"):
            data["fabric"] = cfg

    return {"ok": True, "configs": data}


# ============================================================
# 🔹 POST /api/configs/blockchain/test
# ============================================================
@router.post("/blockchain/test")
async def test_blockchain_config(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    kind = (body.get("kind") or body.get("network") or "polygon").lower()
    tenant_id = user.get("tenant_id", 1)
    manager = BlockchainManager()
    try:
        result = await manager.test_connection(kind, db=db, tenant_id=tenant_id)
        return {"ok": True, **result}
    except Exception as e:
        raise HTTPException(400, f"Blockchain test failed: {e}")


# ============================================================
# 🔹 POST /api/configs/blockchain/deploy
# ============================================================
@router.post("/blockchain/deploy")
async def deploy_contract(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    kind = (body.get("kind") or body.get("network") or "polygon").lower()
    tenant_id = user.get("tenant_id", 1)
    manager = BlockchainManager()
    try:
        result = await manager.deploy_contract(kind, db=db, tenant_id=tenant_id)
        return {"ok": True, **result}
    except Exception as e:
        raise HTTPException(500, f"Blockchain deploy failed: {e}")
