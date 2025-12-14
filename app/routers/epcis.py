from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import text
from sqlalchemy import inspect as sqla_inspect   # dùng cho metadata Model
import inspect as pyinspect                      # dùng để check coroutine
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import DBAPIError
from app.core.db import get_db
from app.security import verify_jwt, check_permission, scope_where_clause
from datetime import datetime
import json, hashlib, uuid, traceback

try:
    from dateutil import parser
except ImportError:
    parser = None

router = APIRouter(prefix="/api/epcis", tags=["epcis"])

# =======================
# ROLE NORMALIZATION
# =======================

def normalize_role_key(raw: str | None, batch_code: str | None = None) -> str:
    """
    Chuẩn hóa role về các tầng Farm/Supplier/Manufacturer/Brand
    Admin thì map theo batch_code
    """
    if not raw:
        return "unknown"

    s = raw.strip().lower()

    # 1. role trực tiếp
    if "farm" in s:
        return "farm"
    if "suppl" in s:
        return "supplier"
    if "manu" in s:
        return "manufacturer"
    if "brand" in s:
        return "brand"

    # 2. Nếu là admin → map theo batch
    if s in ("admin", "superadmin") and batch_code:
        parts = batch_code.split("-")
        # FARM luôn là cấp đầu tiên → EVENT đầu tiên
        # → Nếu ADMIN tạo event cho batch thuộc FARM → coi là FARM
        # → Nếu admin tạo sự kiện ở giai đoạn Supplier → coi là Supplier
        # Cách đơn giản: lấy prefix từ batch_code
        if "SUPPLIER" in parts:
            return "supplier"
        if "MANUFACTURER" in parts:
            return "manufacturer"
        if "BRAND" in parts:
            return "brand"

        # fallback
        return "farm"

    return "unknown"



def parse_batch_code_tiers(batch_code: str):
    """
    Parse batch code theo đúng format:
    GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824
    """
    parts = batch_code.split("-")

    tiers = {
        "farm": None,
        "supplier": None,
        "manufacturer": None,
        "brand": None
    }

    # FARM = phần đầu (vd: GARMENT-001)
    if len(parts) >= 2:
        tiers["farm"] = f"{parts[0]}-{parts[1]}"

    # SUPPLIER
    for i in range(len(parts)):
        if parts[i].upper() == "SUPPLIER" and i + 2 < len(parts):
            tiers["supplier"] = f"{parts[i+1]}-{parts[i+2]}"

        if parts[i].upper() == "MANUFACTURER" and i + 2 < len(parts):
            tiers["manufacturer"] = f"{parts[i+1]}-{parts[i+2]}"

        if parts[i].upper() == "BRAND" and i + 2 < len(parts):
            tiers["brand"] = f"{parts[i+1]}-{parts[i+2]}"

    return tiers


# ----------------------------- Helpers ---------------------------------
async def safe_execute_select(db: AsyncSession, query: str, params: dict | None = None, retry: bool = True):
    params = params or {}
    try:
        await db.rollback()
        return await db.execute(text(query), params)
    except DBAPIError:
        if retry:
            await db.rollback()
            return await safe_execute_select(db, query, params, retry=False)
        raise
    except Exception:
        traceback.print_exc()
        raise

def parse_datetime_safe(value):
    if not value:
        return None
    try:
        if isinstance(value, datetime):
            return value
        if parser:
            return parser.isoparse(value)
        if isinstance(value, str) and value.endswith("Z"):
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        return datetime.fromisoformat(value)
    except Exception:
        return None

async def mark_batch_ready(db: AsyncSession, *, tenant_id: int, batch_code: str, require_events: bool = True):
    if require_events:
        q = await db.execute(
            text("SELECT 1 FROM epcis_events WHERE tenant_id=:t AND batch_code=:b LIMIT 1"),
            {"t": tenant_id, "b": batch_code},
        )
        if not q.first():
            raise HTTPException(400, "Cannot finalize: no EPCIS events captured for this batch")

    await db.execute(text("""
        UPDATE batches
           SET status='READY_FOR_NEXT_LEVEL', updated_at=NOW()
         WHERE tenant_id=:t AND code=:b
    """), {"t": tenant_id, "b": batch_code})
    await db.commit()

def normalize_role(raw: str | None) -> str:
    if not raw:
        return "unknown"

    s = raw.strip().lower()

    # mapping mạnh hơn
    if "farm" in s:
        return "farm"
    if "suppl" in s:
        return "supplier"
    if "manu" in s:
        return "manufacturer"
    if "brand" in s:
        return "brand"

    return "unknown"



# ----------------------------- Capture ---------------------------------
@router.post("/capture")
async def capture_event(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    Ghi nhận EPCIS event mới — hỗ trợ Farm, Supplier, Manufacturer, Brand.
    Supplier có thể tạo EPCIS cho batch của Farm (handoff).
    """
    try:
        if not user or not user.get("tenant_id"):
            raise HTTPException(403, "missing tenant_id")

        tenant_id = int(user["tenant_id"])
        user_role = (user.get("role") or "").upper()
        is_superadmin = (user_role == "SUPERADMIN")
        is_admin = (user_role == "ADMIN")


        batch_code = body.get("batch_code")
        if not batch_code:
            raise HTTPException(400, "batch_code is required")

        doc_bundle_id = body.get("docBundleId")
        if not doc_bundle_id:
            raise HTTPException(400, "docBundleId is required")

        # Lấy thông tin batch
        qb = await db.execute(text("""
            SELECT owner_role, status
            FROM batches
            WHERE tenant_id=:t AND code=:b
            LIMIT 1
        """), {"t": tenant_id, "b": batch_code})
        b = qb.mappings().first()
        if not b:
            raise HTTPException(404, "Batch not found")

        owner_role = (b["owner_role"] or "").upper()
        status = (b["status"] or "").upper()

        # ✅ Superadmin và Admin được phép tạo EPCIS cho mọi batch
        if is_superadmin or is_admin:
            pass
        else:
        # ✅ Chặn nếu batch đã finalize thuộc chính chủ (chỉ áp dụng với user thường)
            if status in ("READY_FOR_NEXT_LEVEL", "CLOSED"):
                if owner_role == user_role:
                    raise HTTPException(403, "Batch finalized — cannot capture more EPCIS")

            elif user_role == "SUPPLIER" and owner_role not in ("SUPPLIER", "FARM"):
                raise HTTPException(403, "Suppliers can only capture EPCIS for SUPPLIER or FARM batches")




        # Dữ liệu event
        event_time = parse_datetime_safe(body.get("eventTime")) or datetime.utcnow()
        event_id = body.get("eventID") or f"urn:uuid:{uuid.uuid4()}"

        # Hash chống trùng
        hash_base = json.dumps({
            "tenant_id": tenant_id,
            "batch_code": batch_code,
            "type": body.get("type"),
            "product_code": body.get("product_code"),
            "material_name": body.get("material_name"),
            "bizStep": body.get("bizStep"),
            "ts": datetime.utcnow().isoformat(),
            "rand": str(uuid.uuid4())
        }, sort_keys=True)
        event_hash = hashlib.sha256(hash_base.encode()).hexdigest()

        # Kiểm tra trùng event_id
        dup = await db.execute(text("SELECT 1 FROM epcis_events WHERE event_id=:eid LIMIT 1"), {"eid": event_id})
        if dup.first():
            raise HTTPException(409, f"Duplicate event_id {event_id}")

        # ✅ Lưu owner_role của người tạo event
        await db.execute(text("""
            INSERT INTO epcis_events(
                tenant_id, owner_role, event_type, batch_code, product_code, material_name,
                event_time, action, biz_step, disposition,
                read_point, biz_location, epc_list, biz_transaction_list,
                ilmd, event_id, event_hash, doc_bundle_id, created_at
            )
            VALUES(
                :tid, :orole, :et, :bc, :pc, :mn,
                :ti, :ac, :bs, :dp,
                :rp, :bl, :el, :bt,
                :il, :eid, :eh, :bundle, NOW()
            )
        """), {
            "tid": tenant_id,
            "orole": user_role,
            "et": body.get("type"),
            "bc": batch_code,
            "pc": body.get("product_code"),
            "mn": body.get("material_name"),
            "ti": event_time,
            "ac": body.get("action"),
            "bs": body.get("bizStep"),
            "dp": body.get("disposition"),
            "rp": json.dumps(body.get("readPoint")),
            "bl": json.dumps(body.get("bizLocation")),
            "el": json.dumps(body.get("epcList")),
            "bt": json.dumps(body.get("bizTransactionList")),
            "il": json.dumps(body.get("ilmd")),
            "eid": event_id,
            "eh": event_hash,
            "bundle": doc_bundle_id,
        })
        await db.commit()

        return {"ok": True, "event_id": event_id, "event_hash": event_hash, "owner_role": user_role}
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        traceback.print_exc()
        raise HTTPException(500, f"EPCIS capture failed: {e}")


# ------------------------------- List -----------------------------------
@router.get("/events")
async def list_events(
    batch_code: str | None = Query(None),
    tenant_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    Logic quyền EPCIS (chuẩn theo workflow Farm -> Supplier):

    - CLOSED → khóa tất cả.
    - OPEN / IN_PROGRESS → chỉ ai tạo event thì được sửa/xóa.
    - READY_FOR_NEXT_LEVEL:
        * Farm (batch_owner)  -> khóa toàn bộ.
        * Supplier (không phải batch_owner):
            - Nếu chưa clone -> chỉ sửa/xóa event của Supplier.
            - Nếu đã clone   -> khóa toàn bộ.

    ✅ Bổ sung:
    - Dùng VIEW `v_batch_overview` để hiển thị định lượng batch:
      quantity, used_quantity, remaining_quantity, unit, last_event_time
    - Thêm quyền superadmin được phép xem/sửa/xóa tất cả.
    """
    try:
        tenant_user = int(user.get("tenant_id") or 0)
        user_role = (user.get("role") or "").upper()
        is_superadmin = (user_role == "SUPERADMIN")
        is_admin = (user_role == "ADMIN")
        # --- Scope ---
        result = scope_where_clause(db, user, "events")
        where_clause = await result if hasattr(result, "__await__") else (result or "1=1")
        if "tenant_id" in where_clause and "e.tenant_id" not in where_clause:
            where_clause = where_clause.replace("tenant_id", "e.tenant_id")

        has_tenant_scope = "e.tenant_id" in where_clause.lower()
        params = {}

        # --- Lấy meta batch (owner, status, clone flag + quantity info) ---
        meta_owner = meta_status = None
        meta_cloned = None
        meta_quantity = meta_remaining = meta_used = None
        meta_unit = None

        if batch_code:
            qb = await db.execute(text("""
                SELECT v.owner_role, v.status, b.next_level_cloned_at,
                       v.quantity, v.used_quantity, v.remaining_quantity, v.unit
                FROM v_batch_overview v
                JOIN batches b
                  ON v.batch_code=b.code AND v.tenant_id=b.tenant_id
                WHERE v.tenant_id=:t AND v.batch_code=:b
                LIMIT 1
            """), {"t": tenant_id or tenant_user, "b": batch_code})
            br = qb.mappings().first()
            if br:
                meta_owner = (br["owner_role"] or "").upper()
                meta_status = (br["status"] or "").upper()
                meta_cloned = br["next_level_cloned_at"]
                meta_quantity = float(br["quantity"] or 0)
                meta_used = float(br["used_quantity"] or 0)
                meta_remaining = float(br["remaining_quantity"] or 0)
                meta_unit = br["unit"] or ""

        # --- Truy vấn EPCIS event ---
        q = f"""
            SELECT e.id, e.tenant_id, e.owner_role AS event_owner_role,
                   e.event_type, e.batch_code, e.product_code, e.material_name,
                   e.event_time, e.action, e.biz_step, e.disposition,
                   e.event_id, e.doc_bundle_id, e.created_at,
                   e.read_point, e.biz_location,
                   e.epc_list, e.biz_transaction_list, e.ilmd,
                   COALESCE(v.owner_role, 'UNKNOWN') AS batch_owner_role_join,
                   COALESCE(v.status, '') AS batch_status_join,
                   COALESCE(v.quantity, 0) AS batch_quantity,
                   COALESCE(v.remaining_quantity, 0) AS remaining_quantity,
                   COALESCE(v.used_quantity, 0) AS used_quantity,
                   COALESCE(v.unit, '') AS batch_unit
            FROM epcis_events e
            LEFT JOIN v_batch_overview v
              ON e.batch_code=v.batch_code AND e.tenant_id=v.tenant_id
            WHERE {where_clause}
        """
        if not has_tenant_scope:
            q += " AND e.tenant_id=:tenant_id"
            params["tenant_id"] = tenant_id or tenant_user
        if batch_code:
            q += " AND e.batch_code=:batch_code"
            params["batch_code"] = batch_code
        q += " ORDER BY e.created_at DESC LIMIT 200"

        res = await safe_execute_select(db, q, params)
        rows = res.mappings().all()

        def j(v):
            try:
                return json.loads(v) if v else None
            except Exception:
                return v

        eff_owner = (meta_owner or "").upper()
        eff_status = (meta_status or "").upper()

        items = []
        for r in rows:
            event_owner = (r["event_owner_role"] or "").upper()
            row_b_owner = (r["batch_owner_role_join"] or "").upper()
            row_b_status = (r["batch_status_join"] or "").upper()

            batch_owner = eff_owner or row_b_owner
            batch_status = eff_status or row_b_status

            editable = deletable = False

            # ----- PHÂN QUYỀN CHI TIẾT -----
            if is_superadmin or is_admin:
                editable = deletable = True
            else:
                if batch_status == "CLOSED":
                    editable = deletable = False
                elif batch_status == "READY_FOR_NEXT_LEVEL":
                    if user_role == batch_owner:
                        editable = deletable = False
                    else:
                        if not meta_cloned:  # chưa clone sang level tiếp theo
                            if event_owner == user_role:
                                editable = deletable = True
                        else:
                            editable = deletable = False
                else:
                    # OPEN / IN_PROGRESS
                    if event_owner == user_role:
                        editable = deletable = True

            d = dict(r)
            d["epc_list"] = j(d.get("epc_list"))
            d["biz_transaction_list"] = j(d.get("biz_transaction_list"))
            d["ilmd"] = j(d.get("ilmd"))

            # --- Thông tin batch ---
            batch_qty = float(r.get("batch_quantity") or 0)
            used_qty = float(r.get("used_quantity") or 0)
            remaining_qty = float(r.get("remaining_quantity") or 0)
            unit = r.get("batch_unit") or meta_unit or ""

            d["batch_quantity"] = batch_qty
            d["used_quantity"] = used_qty
            d["remaining_quantity"] = remaining_qty
            d["unit"] = unit

            d["owner_role"] = event_owner
            d["batch_owner_role"] = batch_owner
            d["batch_status"] = batch_status
            d["editable"] = bool(editable)
            d["deletable"] = bool(deletable)
            items.append(d)

        # --- Meta cho nút Add EPCIS Event ---
        can_create = False
        if is_superadmin or is_admin:
            can_create = True
        elif eff_owner and eff_status:
            if (
                eff_owner == "FARM"
                and eff_status == "READY_FOR_NEXT_LEVEL"
                and user_role == "SUPPLIER"
                and not meta_cloned
            ):
                can_create = True
            elif user_role == eff_owner and eff_status not in ("READY_FOR_NEXT_LEVEL", "CLOSED"):
                can_create = True
        # ✅ Admin và Superadmin luôn được phép thêm EPCIS Event
        if is_superadmin or is_admin:
            can_create = True

        return {
            "items": items,
            "meta": {
                "batch_owner_role": eff_owner,
                "batch_status": eff_status,
                "can_create": can_create,
                "has_cloned": bool(meta_cloned),
                "requester_role": user_role,
                "batch_quantity": meta_quantity,
                "used_quantity": meta_used,
                "remaining_quantity": meta_remaining,
                "unit": meta_unit,
            },
        }

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(500, f"EPCIS list failed: {e}")

# ------------------------------ Update ----------------------------------
@router.put("/events/{event_id}")
async def update_event(event_id: str, body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        tenant_id = int(user.get("tenant_id") or 0)
        user_role = (user.get("role") or "").upper()
        is_superadmin = (user_role == "SUPERADMIN")
        is_admin = (user_role == "ADMIN")

        # Lấy batch info
        q = await db.execute(text("""
            SELECT e.batch_code, e.tenant_id, b.owner_role, b.status
            FROM epcis_events e
            JOIN batches b
              ON e.batch_code=b.code AND e.tenant_id=b.tenant_id
           WHERE e.event_id=:eid AND e.tenant_id=:t
        """), {"eid": event_id, "t": tenant_id})
        row = q.mappings().first()
        if not row:
            raise HTTPException(404, "Event not found")

        owner_role = (row["owner_role"] or "").upper()
        status = (row["status"] or "").upper()

        # Quyền
        if not (is_superadmin or is_admin):
            if status in ("READY_FOR_NEXT_LEVEL", "CLOSED"):
                raise HTTPException(403, "Cannot modify events of finalized batch")
            if user_role != owner_role:
                raise HTTPException(403, "You can only modify events of your own role")

        # Parse time
        event_time = parse_datetime_safe(body.get("eventTime")) or datetime.utcnow()

        # 👉 UPDATE CHÍNH XÁC TẤT CẢ FIELDS
        res = await db.execute(text("""
            UPDATE epcis_events
               SET 
                   product_code        = :p,
                   material_name       = :mn,
                   event_type          = :et,
                   event_time          = :ti,
                   action              = :a,
                   biz_step            = :bs,
                   disposition         = :d,
                   doc_bundle_id       = :bundle,
                   read_point          = :rp,
                   biz_location        = :bl,
                   epc_list            = :el,
                   biz_transaction_list = :bt,
                   ilmd                = :il
             WHERE event_id=:eid AND tenant_id=:t
         RETURNING id,event_id,product_code,event_time,created_at
        """), {
            "p": body.get("product_code"),
            "mn": body.get("material_name"),
            "et": body.get("type"),
            "ti": event_time,
            "a": body.get("action"),
            "bs": body.get("bizStep"),
            "d": body.get("disposition"),
            "bundle": body.get("docBundleId"),
            # 💡 NEW — SAVE READPOINT / BIZLOCATION ĐÚNG CHUẨN
            "rp": json.dumps(body.get("readPoint")),
            "bl": json.dumps(body.get("bizLocation")),
            # 💡 NEW — SAVE EPC LIST
            "el": json.dumps(body.get("epcList") or []),
            # 💡 NEW — SAVE BIZ TX
            "bt": json.dumps(body.get("bizTransactionList") or []),
            # 💡 NEW — SAVE ILMD + DPP
            "il": json.dumps(body.get("ilmd") or {}),
            "eid": event_id,
            "t": tenant_id,
        })

        await db.commit()
        row = res.mappings().first()
        return {"ok": True, "data": dict(row), "updated_by": user_role}

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(400, str(e))



# ------------------------------ Delete ----------------------------------
@router.delete("/events/{event_id}")
async def delete_event(event_id: str, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        tenant_id = int(user.get("tenant_id") or 0)
        user_role = (user.get("role") or "").upper()
        is_superadmin = (user_role == "SUPERADMIN")
        is_admin = (user_role == "ADMIN")

        q = await db.execute(text("""
            SELECT e.batch_code, e.tenant_id, b.owner_role, b.status
            FROM epcis_events e
            JOIN batches b
              ON e.batch_code=b.code AND e.tenant_id=b.tenant_id
           WHERE e.event_id=:eid AND e.tenant_id=:t
        """), {"eid": event_id, "t": tenant_id})
        row = q.mappings().first()
        if not row:
            raise HTTPException(404, "Event not found")

        owner_role = (row["owner_role"] or "").upper()
        status = (row["status"] or "").upper()

        # ✅ Superadmin bypass toàn quyền
        if not (is_superadmin or is_admin):
            if status in ("READY_FOR_NEXT_LEVEL", "CLOSED"):
                raise HTTPException(403, "Cannot delete events of finalized batch")
            if user_role != owner_role:
                raise HTTPException(403, "You can only delete events of your own role")

        await db.execute(text("DELETE FROM epcis_events WHERE event_id=:eid AND tenant_id=:t"),
                         {"eid": event_id, "t": tenant_id})
        await db.commit()
        return {"ok": True, "deleted_by": user_role}

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"Delete failed: {e}")


# ============================================================
# 📦 Lấy config publish
# ============================================================
@router.get("/publish-config")
async def get_publish_config(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        tenant_id = user.get("tenant_id") or 1
        q = await db.execute(text("""
            SELECT rpc_url, contract_address, COALESCE(private_key,''), config_json
            FROM configs_blockchain WHERE is_default=TRUE ORDER BY id DESC LIMIT 1
        """))
        r = q.first()
        polygon, fabric = {}, {}
        if r:
            rpc, contract, pk, cfg = r
            cfgd = cfg if isinstance(cfg, dict) else json.loads(cfg or "{}")

            polygon = {
                "chain_name": "Polygon",
                "rpc_url": rpc,
                "contract_address": contract,
                "private_key": pk,
                "chain_id": int(cfgd.get("chain_id", 80002)),
                "gas_limit": int(cfgd.get("gas_limit", 8000000)),
                "max_fee_gwei": int(cfgd.get("max_fee_gwei", 120)),
                "priority_fee_gwei": int(cfgd.get("priority_fee_gwei", 40))
            }

        fabric = {
            "chain_name": "Fabric",
            "gateway_url": "grpc://localhost:7051",
            "channel": "mychannel",
            "chaincode": "proof_cc"
        }

        return {"tenant_id": tenant_id, "polygon": polygon, "fabric": fabric}

    except Exception as e:
        raise HTTPException(500, f"get config failed: {e}")

# ============================================================
# ✅ Publish batch lên Polygon (real mode)
# ============================================================
from app.blockchain.polygon_adapter import PolygonAdapter

@router.post("/publish-to-blockchain")
async def publish_batch_to_blockchain(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    try:
        batch_code = body.get("batch_code")
        if not batch_code:
            raise HTTPException(400, "batch_code is required")

        tenant_id = user.get("tenant_id")
        if not tenant_id:
            raise HTTPException(403, "missing tenant_id")

        q = await db.execute(text("SELECT event_hash FROM epcis_events WHERE tenant_id=:t AND batch_code=:b ORDER BY id"),
                             {"t": tenant_id, "b": batch_code})
        hashes = [r[0] for r in q.fetchall()]
        if not hashes:
            raise HTTPException(404, "No EPCIS events found")
        root_hash = hashlib.sha256("".join(hashes).encode()).hexdigest()

        cfg = await db.execute(text("""
            SELECT rpc_url, contract_address, COALESCE(private_key,''), config_json
            FROM configs_blockchain WHERE is_default=TRUE ORDER BY id DESC LIMIT 1
        """))
        r = cfg.first()
        if not r:
            raise HTTPException(500, "Blockchain config not found")

        rpc, contract, pk, cfgj = r
        base = cfgj if isinstance(cfgj, dict) else json.loads(cfgj or "{}")

        override = body.get("polygon_override", {})
        eff = {
            "rpc_url": override.get("rpc_url", rpc),
            "contract_address": override.get("contract_address", contract),
            "private_key": override.get("private_key", pk),
            "chain_id": int(override.get("chain_id", base.get("chain_id", 80002)))
        }

        adapter = PolygonAdapter(
            rpc_url=eff["rpc_url"],
            contract_address=eff["contract_address"],
            private_key=eff["private_key"],
            tenant_id=tenant_id,
            config_json=eff,
        )

        result = await adapter.anchor_batch(
            bundle_id=batch_code,
            batch_hash=root_hash,
            meta={"tenant_id": tenant_id, "count": len(hashes)},
        )

        tx = result.get("tx_hash")
        block = result.get("block_number")
        status = result.get("status", "FAILED")

        if not tx:
            if "insufficient funds" in str(result).lower():
                status = "INSUFFICIENT_FUNDS"
            else:
                status = "FAILED"

        await db.execute(text("""
            INSERT INTO blockchain_proofs(tenant_id,batch_code,network,tx_hash,block_number,root_hash,status,created_at)
            VALUES(:t,:b,'polygon',:tx,:bn,:rh,:st,NOW())
            ON CONFLICT(batch_code) DO UPDATE
            SET tx_hash=:tx,block_number=:bn,root_hash=:rh,status=:st,updated_at=NOW()
        """), {"t": tenant_id, "b": batch_code, "tx": tx, "bn": block, "rh": root_hash, "st": status})
        await db.commit()

        # 🔔 Nếu publish thành công → cho phép chuyển tầng
        if status not in ("FAILED", "INSUFFICIENT_FUNDS"):
            await mark_batch_ready(db, tenant_id=tenant_id, batch_code=batch_code, require_events=True)

        return {
            "ok": True,
            "tx_hash": tx,
            "block_number": block,
            "status": status,
            "root_hash": root_hash,
            "network": "polygon",
        }

    except Exception as e:
        await db.rollback()
        traceback.print_exc()
        raise HTTPException(500, f"Publish failed: {e}")

# ============================================================
# 🟢 Finalize batch thủ công (không cần anchor blockchain)
# ============================================================
@router.post("/finalize-batch")
async def finalize_batch(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    Farm/Supplier/Manufacturer/Brand gọi endpoint này sau khi đã capture đủ EPCIS events.
    Hệ quả: batches.status = READY_FOR_NEXT_LEVEL → tenant kế tiếp mới nhìn thấy.
    """
    try:
        tenant_id = user.get("tenant_id")
        if not tenant_id:
            raise HTTPException(403, "missing tenant_id")

        batch_code = body.get("batch_code")
        if not batch_code:
            raise HTTPException(400, "batch_code is required")

        await mark_batch_ready(db, tenant_id=tenant_id, batch_code=batch_code, require_events=True)
        return {"ok": True, "batch_code": batch_code, "status": "READY_FOR_NEXT_LEVEL"}
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"Finalize failed: {e}")
        

# ============================================================
# 🟢 FULL TIMELINE — GROUP EPCIS + DPP THEO TỪNG TẦNG
# ============================================================

@router.get("/dpp/full-timeline")
async def get_full_timeline(
    batch_code: str = Query(...),
    db: AsyncSession = Depends(get_db),
):
    """
    Option A — Multi-tier timeline từ EPCIS events
    FE yêu cầu: farm / supplier / manufacturer / brand / unknown
    """

    tiers = parse_batch_code_tiers(batch_code)

    rs = await db.execute(
        text(
            """
            SELECT
                id,
                owner_role,
                batch_code,
                event_time,
                action,
                biz_step,
                disposition,
                event_id,
                read_point,
                biz_location,
                epc_list,
                ilmd
            FROM epcis_events
            WHERE batch_code = :bc
            ORDER BY event_time ASC, id ASC
            """
        ),
        {"bc": batch_code},
    )
    rows = rs.mappings().all()

    timeline = {
        "farm": [],
        "supplier": [],
        "manufacturer": [],
        "brand": [],
        "unknown": [],
    }

    def safe_json(v):
        if v is None:
            return None
        if isinstance(v, (dict, list)):
            return v
        try:
            return json.loads(v)
        except:
            return v

    for r in rows:
        ev = dict(r)

        ev["read_point"] = safe_json(ev.get("read_point"))
        ev["biz_location"] = safe_json(ev.get("biz_location"))
        ev["epc_list"] = safe_json(ev.get("epc_list"))
        ev["ilmd"] = safe_json(ev.get("ilmd"))

        try:
            ev = normalize_dpp(ev)
        except:
            pass

        raw_role = ev.get("owner_role")
        norm_role = normalize_role_key(raw_role, batch_code)

        ev["role"] = norm_role.upper()

        if norm_role not in timeline:
            timeline["unknown"].append(ev)
        else:
            timeline[norm_role].append(ev)

    return {
        "batch_code": batch_code,
        "tiers": tiers,
        "timeline": timeline,
        "total_events": sum(len(v) for v in timeline.values()),
    }



# -----------------------------
# Nomalize DPP
# -----------------------------

def normalize_dpp(ev: dict) -> dict:
    """
    Chuẩn hóa ILMD / DPP để FE hiển thị ổn định.

    Chuẩn:
        - ev["ilmd"] có thể dạng string / dict
        - ilmd["dpp"] chứa metadata DPP
        - Trả về ev có trường "dpp" đã chuẩn hóa
    """

    ilmd_raw = ev.get("ilmd")

    if ilmd_raw is None:
        ev["dpp"] = None
        return ev

    # Parse nếu là JSON string
    if isinstance(ilmd_raw, str):
        try:
            ilmd = json.loads(ilmd_raw)
        except Exception:
            ilmd = {}
    elif isinstance(ilmd_raw, dict):
        ilmd = ilmd_raw
    else:
        ilmd = {}

    # Lấy DPP block từ ILMD
    dpp = ilmd.get("dpp") or ilmd.get("DPP") or ilmd

    # Chuẩn hóa: nếu không phải dict thì bỏ qua
    if not isinstance(dpp, dict):
        ev["dpp"] = None
        return ev

    # Bổ sung key mặc định tránh lỗi FE
    default_fields = [
        "cost_info", "transport", "use_phase", "brand_info", "circularity",
        "composition", "end_of_life", "supply_chain", "documentation",
        "health_safety", "quantity_info", "social_impact", "animal_welfare",
        "digital_identity", "product_description", "environmental_impact"
    ]

    for field in default_fields:
        dpp.setdefault(field, {})

    # Ghi lại vào ev
    ev["dpp"] = dpp
    return ev



# ============================================================
# Block 2 — Chuẩn hóa DPP (fix missing DPP, merge format)
# ============================================================

def normalize_role(raw: str | None) -> str:
    if not raw:
        return "unknown"

    s = raw.strip().lower()

    if "farm" in s:
        return "farm"
    if "suppl" in s:
        return "supplier"
    if "manu" in s:
        return "manufacturer"
    if "brand" in s:
        return "brand"

    return "unknown"


def resolve_event_role(ev: dict, batch_owner: str | None = None) -> str:
    """
    Ưu tiên:
      1. owner_role (vì DB không có event_creator_role)
      2. batch_owner_role
      3. batch_owner (fallback)
    """
    raw = (
        ev.get("owner_role")
        or ev.get("batch_owner_role")
        or batch_owner
        or ""
    )
    return normalize_role(str(raw))




async def load_timeline_with_dpp(db: AsyncSession, batch_code: str):
    sql = """
        SELECT 
            id,
            owner_role AS role,
            batch_code,
            event_time,
            action,
            biz_step,
            disposition,
            event_id,
            read_point,
            biz_location,
            epc_list,
            ilmd
        FROM epcis_events
        WHERE batch_code = :b
        ORDER BY event_time ASC
    """

    rs = await db.execute(text(sql), {"b": batch_code})
    rows = rs.mappings().all()

    grouped = {
        "farm": [],
        "supplier": [],
        "manufacturer": [],
        "brand": [],
        "unknown": [],
    }

    for r in rows:
        ev = dict(r)
        ev = normalize_dpp(ev)

        role = normalize_role(ev.get("role"))
        grouped[role].append(ev)

    return grouped


def infer_role_from_batch_code(batch_code: str, event_time):
    """
    HOTFIX: Suy ra role dựa vào timestamp trong batch_code.
    batch_code:
      GARMENT-001-SUPPLIER-251119-0812-MANUFACTURER-251119-0817-BRAND-251119-0824
    """
    parts = batch_code.split("-")

    # Extract timestamps
    def extract_ts(label):
        if label not in parts:
            return None
        i = parts.index(label)
        if i + 2 < len(parts):
            ts = parts[i+1] + parts[i+2]
            try:
                # format DDMMYYHHMM
                return datetime.strptime(ts, "%d%m%y%H%M")
            except:
                return None
        return None

    ts_supplier = extract_ts("SUPPLIER")
    ts_manu = extract_ts("MANUFACTURER")
    ts_brand = extract_ts("BRAND")

    # event_time is datetime already
    t = event_time

    # FARM: trước supplier timestamp
    if ts_supplier and t < ts_supplier:
        return "farm"

    # SUPPLIER: giữa supplier & manufacturer
    if ts_supplier and ts_manu and ts_supplier <= t < ts_manu:
        return "supplier"

    # MANUFACTURER: giữa manufacturer & brand
    if ts_manu and ts_brand and ts_manu <= t < ts_brand:
        return "manufacturer"

    # BRAND: sau brand timestamp
    if ts_brand and t >= ts_brand:
        return "brand"

    return "unknown"


