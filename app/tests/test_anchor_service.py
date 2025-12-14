import pytest
from unittest.mock import AsyncMock, patch
from app.services.anchor_service import publish_batch_to_blockchain

# ==========================================================
# 🔹 Giả lập dữ liệu cấu hình blockchain
# ==========================================================
MOCK_CHAIN_CONFIG = {
    "id": 1,
    "tenant_id": 1,
    "network": "polygon-amoy",
    "rpc_url": "https://rpc-amoy.polygon.technology",
    "contract_address": "0x755533D680EC8AfCE19c375eB14734618473EC59",
    "config_json": {
        "mode": "mock",
        "chain_id": 80002,
        "private_key": "0xFAKE_PRIVATE_KEY",
        "gas_limit": 120000,
        "max_fee_gwei": 10,
        "priority_fee_gwei": 1
    }
}


@pytest.mark.asyncio
async def test_publish_batch_success(monkeypatch):
    """
    ✅ Kiểm thử đường đi thành công:
    - Batch chưa được anchor
    - Config blockchain có sẵn
    - Adapter trả về CONFIRMED
    - Ghi log DB thành công
    """

    # 1️⃣ Mock database layer
    mock_db = AsyncMock()

    async def mock_get_chain_config(db, tenant_id):
        return MOCK_CHAIN_CONFIG

    async def mock_is_anchored(db, tenant_id, bundle_id, network):
        return None  # chưa anchor

    async def mock_insert_anchor(db, payload):
        return True

    # 2️⃣ Mock PolygonAdapter.anchor_batch()
    async def mock_anchor_batch(self, bundle_id, batch_hash, meta):
        return {
            "network": "polygon-amoy",
            "tx_hash": "0xFAKE_TX_HASH",
            "block_number": 123456,
            "status": "CONFIRMED",
            "ts": "2025-10-21T08:00:00Z"
        }

    # 3️⃣ Áp dụng monkeypatch
    monkeypatch.setattr("app.services.dao_anchor.get_chain_config", mock_get_chain_config)
    monkeypatch.setattr("app.services.dao_anchor.is_anchored", mock_is_anchored)
    monkeypatch.setattr("app.services.dao_anchor.insert_anchor", mock_insert_anchor)
    monkeypatch.setattr("app.blockchain.adapters.polygon_adapter.PolygonAdapter.anchor_batch", mock_anchor_batch)

    # 4️⃣ Chạy hàm chính
    result = await publish_batch_to_blockchain(
        db=mock_db,
        tenant_id=1,
        bundle_id="LOT-2025-10",
        root_hash="0xDEADBEEF"
    )

    # 5️⃣ Kiểm tra kết quả
    assert result["ok"] is True
    assert result["status"] == "CONFIRMED"
    assert "tx_hash" in result
    assert result["network"] == "polygon-amoy"


@pytest.mark.asyncio
async def test_publish_batch_already_anchored(monkeypatch):
    """
    🟡 Trường hợp batch đã được anchor trước đó
    -> Hàm sẽ bỏ qua và trả về SKIPPED
    """
    mock_db = AsyncMock()

    async def mock_is_anchored(db, tenant_id, bundle_id, network):
        return {"tx_hash": "0xOLD_TX", "network": "polygon-amoy"}

    async def mock_get_chain_config(db, tenant_id):
        return MOCK_CHAIN_CONFIG

    monkeypatch.setattr("app.services.dao_anchor.is_anchored", mock_is_anchored)
    monkeypatch.setattr("app.services.dao_anchor.get_chain_config", mock_get_chain_config)

    result = await publish_batch_to_blockchain(mock_db, 1, "LOT-2025-10", "0xABCDEF")

    assert result["ok"] is False
    assert result["status"] == "SKIPPED"
    assert "existing_tx" in result


@pytest.mark.asyncio
async def test_publish_batch_missing_config(monkeypatch):
    """
    🔴 Thiếu cấu hình blockchain -> Lỗi
    """
    mock_db = AsyncMock()

    async def mock_get_chain_config(db, tenant_id):
        return None  # Không có cấu hình blockchain

    monkeypatch.setattr("app.services.dao_anchor.get_chain_config", mock_get_chain_config)
    monkeypatch.setattr("app.services.dao_anchor.is_anchored", AsyncMock(return_value=None))

    result = await publish_batch_to_blockchain(mock_db, 1, "LOT-2025-11", "0xDEADBEEF")

    assert result["ok"] is False
    assert "Blockchain configuration not found" in result["error"]


@pytest.mark.asyncio
async def test_publish_batch_anchor_failed(monkeypatch):
    """
    🔴 Trường hợp anchor thất bại do lỗi RPC hoặc ký giao dịch
    """
    mock_db = AsyncMock()

    async def mock_get_chain_config(db, tenant_id):
        return MOCK_CHAIN_CONFIG

    async def mock_is_anchored(db, tenant_id, bundle_id, network):
        return None

    async def mock_anchor_batch(self, bundle_id, batch_hash, meta):
        return {"status": "FAILED", "error": "insufficient funds"}

    monkeypatch.setattr("app.services.dao_anchor.get_chain_config", mock_get_chain_config)
    monkeypatch.setattr("app.services.dao_anchor.is_anchored", mock_is_anchored)
    monkeypatch.setattr("app.blockchain.adapters.polygon_adapter.PolygonAdapter.anchor_batch", mock_anchor_batch)

    result = await publish_batch_to_blockchain(mock_db, 1, "LOT-FAIL", "0x123456")

    assert result["ok"] is False
    assert result["error"] == "insufficient funds"
