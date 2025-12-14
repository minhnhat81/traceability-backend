from datetime import datetime, date
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Body

# ✅ Dự phòng nếu check_permission chưa được định nghĩa trong app.security
async def check_permission(db, user, module, action, body=None, path=None, method=None):
    if not user or "tenant_id" not in user:
        return False
    return True
# ✅ Get split mode
async def get_split_mode(db: AsyncSession, role: str) -> str:
    """Đọc chính sách chia tách (FULL / SPLIT) từ bảng split_policy"""
    res = await db.execute(
        text("SELECT mode FROM split_policy WHERE LOWER(role)=LOWER(:r)"),
        {"r": role}
    )
    mode = res.scalar()
    return mode or "FULL"

# ✅ map tenant kế tiếp cho next_role (ưu tiên body.next_tenant_id nếu truyền vào)
async def resolve_next_tenant_id(
    db: AsyncSession,
    current_tenant_id: int,
    next_role: str,
    body_next_tenant_id: Optional[int] = None,
) -> int:
    if body_next_tenant_id:
        return int(body_next_tenant_id)

    # Ví dụ bảng: supply_chain_links(tenant_id, next_role, next_tenant_id)
    res = await db.execute(
        text("""
            SELECT next_tenant_id
            FROM supply_chain_links
            WHERE tenant_id = :t AND LOWER(next_role) = LOWER(:r)
            ORDER BY id DESC
            LIMIT 1
        """),
        {"t": current_tenant_id, "r": next_role},
    )
    nid = res.scalar()
    if nid:
        return int(nid)

    # fallback cuối cùng: nếu chưa cấu hình, vẫn để cùng tenant để không vỡ luồng
    return current_tenant_id


# ✅ CHỈ KHAI BÁO MỘT ROUTER DUY NHẤT
router = APIRouter(prefix="/api/batches", tags=["batches"])


# ============================================================
# ✅ GET: Danh sách batches theo tầng & trạng thái "sẵn sàng"
# ============================================================
# ============================================================
# ✅ GET: Danh sách batches theo tầng & trạng thái "sẵn sàng"
# ============================================================
@router.get("/")
async def list_batches(
    level: Optional[str] = Query(None, regex="^(farm|supplier|manufacturer|brand)$"),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    if not user or "tenant_id" not in user:
        raise HTTPException(403, "unauthorized or missing tenant_id")

    tenant_id = user["tenant_id"]
    role = (user.get("role") or "farm").lower()
    lv = (level or role).lower()

    # 🔹 map level → owner_role “chuẩn” (farm / supplier / manufacturer / brand)
    role_map = {
        "farm": "farm",
        "supplier": "supplier",
        "manufacturer": "manufacturer",
        "brand": "brand",
    }
    owner_role = role_map.get(lv, "farm")

    # 🔹 dùng LOWER(...) để không bị lệ thuộc chữ hoa / thường trong DB
    if owner_role == "farm":
        where_core = "LOWER(b.owner_role) = 'farm'"
    elif owner_role == "supplier":
        # Supplier:
        #  - thấy các batch thuộc supplier
        #  - (tùy chọn) có thể thấy thêm batch farm đã READY_FOR_NEXT_LEVEL (nếu bạn muốn)
        where_core = "(" \
                     "  LOWER(b.owner_role) = 'supplier'" \
                     "  OR (LOWER(b.owner_role) = 'farm' AND b.status = 'READY_FOR_NEXT_LEVEL')" \
                     ")"
    elif owner_role == "manufacturer":
        where_core = "(" \
                     "  LOWER(b.owner_role) = 'manufacturer'" \
                     "  OR (LOWER(b.owner_role) = 'supplier' AND b.status = 'READY_FOR_NEXT_LEVEL')" \
                     ")"
    elif owner_role == "brand":
        where_core = "(" \
                     "  LOWER(b.owner_role) = 'brand'" \
                     "  OR (LOWER(b.owner_role) = 'manufacturer' AND b.status = 'READY_FOR_NEXT_LEVEL')" \
                     ")"
    else:
        where_core = "TRUE"

    query = text(f"""
        SELECT 
            b.id, b.code, b.product_code, b.mfg_date, b.country,
            b.quantity, b.unit, b.status, b.material_type,
            b.description, b.blockchain_tx_hash, b.origin_farm_id,
            b.owner_role, b.created_at,
            COALESCE(SUM(bl.material_used), 0) AS total_used,
            p.code AS parent_batch_code,
            p.owner_role AS parent_owner_role
        FROM batches b
        LEFT JOIN batch_links bl
               ON bl.parent_batch_id = b.id OR bl.child_batch_id = b.id
        LEFT JOIN batches p
               ON p.id = bl.parent_batch_id
        WHERE b.tenant_id = :t
          AND {where_core}
        GROUP BY b.id, p.code, p.owner_role
        ORDER BY b.id DESC
        LIMIT 500
    """)

    result = await db.execute(query, {"t": tenant_id})
    rows = result.fetchall()

    items = []
    for r in rows:
        used = float(r.total_used or 0)
        remain = float(r.quantity or 0) - used
        items.append({
            "id": r.id,
            "code": r.code,
            "product_code": r.product_code,
            "mfg_date": (
                r.mfg_date.strftime("%Y-%m-%d")
                if isinstance(r.mfg_date, (datetime, date))
                else ""
            ),
            "country": r.country,
            "quantity": float(r.quantity or 0),
            "used": used,
            "remaining": remain if remain >= 0 else 0,
            "unit": r.unit or "",
            "status": r.status,
            "material_type": r.material_type,
            "description": r.description,
            "blockchain_tx_hash": r.blockchain_tx_hash,
            "owner_role": r.owner_role,
            "parent_batch_code": r.parent_batch_code,
            "parent_owner_role": r.parent_owner_role,
            "created_at": (
                r.created_at.strftime("%Y-%m-%d %H:%M:%S")
                if isinstance(r.created_at, datetime)
                else ""
            ),
        })

    return {"items": items}


# ============================================================
# ✅ POST: Tạo batch mới
# ============================================================
@router.post("/")
async def create_batch(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    if not user or "tenant_id" not in user:
        raise HTTPException(403, "unauthorized or missing tenant_id")

    tenant_id = user["tenant_id"]
    code = body.get("code")
    product_code = body.get("product_code")
    if not code or not product_code:
        raise HTTPException(400, "Missing code or product_code")

    exists = await db.execute(text("SELECT id FROM batches WHERE code=:c AND tenant_id=:t"), {"c": code, "t": tenant_id})
    if exists.first():
        raise HTTPException(400, f"Batch {code} already exists")

    mfg_date = body.get("mfg_date")
    if isinstance(mfg_date, str) and mfg_date:
        try:
            mfg_date = datetime.strptime(mfg_date, "%Y-%m-%d").date()
        except Exception:
            mfg_date = None

    await db.execute(text("""
        INSERT INTO batches (
            tenant_id, code, product_code, mfg_date, country, quantity,
            status, material_type, description, owner_role, created_at
        ) VALUES (
            :t, :code, :prod, :mfg, :country, :qty,
            'OPEN', :mat, :desc, :role, NOW()
        )
    """), {
        "t": tenant_id,
        "code": code,
        "prod": product_code,
        "mfg": mfg_date,
        "country": body.get("country"),
        "qty": body.get("quantity"),
        "mat": body.get("material_type"),
        "desc": body.get("description"),
        "role": body.get("owner_role") or "farm"
    })
    await db.commit()
    return {"ok": True, "message": f"Batch {code} created successfully"}


# ============================================================
# ✅ POST: Finalize batch
# ============================================================
@router.post("/finalize")
async def finalize_batch(body: dict = Body(...), db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    tenant_id = user.get("tenant_id")
    batch_code = body.get("batch_code")
    if not tenant_id or not batch_code:
        raise HTTPException(400, "Missing tenant_id or batch_code")

    result = await db.execute(text("SELECT id FROM batches WHERE code=:c AND tenant_id=:t"), {"c": batch_code, "t": tenant_id})
    if not result.first():
        raise HTTPException(404, f"Batch {batch_code} not found")

    await db.execute(text("""
        UPDATE batches
        SET status='READY_FOR_NEXT_LEVEL'
        WHERE code=:c AND tenant_id=:t
    """), {"c": batch_code, "t": tenant_id})
    await db.commit()
    return {"ok": True, "message": f"Batch {batch_code} marked READY_FOR_NEXT_LEVEL"}


# ============================================================
# ✅ POST: Clone batch sang tầng tiếp theo (bổ sung usage & tồn kho)
# ============================================================
@router.post("/clone_for_next_level")
async def clone_for_next_level(
    body: dict,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(400, "Missing tenant_id")

    batch_code = body.get("batch_code")
    if not batch_code:
        raise HTTPException(400, "Missing batch_code")

    input_used = float(body.get("used_quantity") or 0)
    converted_unit = body.get("converted_unit")
    converted_rate = body.get("converted_rate")

    # 🔎 load batch cha
    res = await db.execute(
        text("SELECT * FROM batches WHERE code=:c AND tenant_id=:t"),
        {"c": batch_code, "t": tenant_id},
    )
    src = res.mappings().first()
    if not src:
        raise HTTPException(404, f"Batch {batch_code} not found")

    # ==========================================
    # 🔥 TẦNG TIẾP THEO (không đổi logic)
    # ==========================================
    batch_owner = (src["owner_role"] or "").lower()
    next_role_map = {
        "farm": "supplier",
        "supplier": "manufacturer",
        "manufacturer": "brand",
    }
    next_role = next_role_map.get(batch_owner)
    if not next_role:
        raise HTTPException(400, f"No next level for batch owner '{batch_owner}'")

    # ==========================================
    # ❗🔥 SINGLE-TENANT MODE – quan trọng
    # → tất cả cùng tenant_id = 1
    # ==========================================
    child_tenant_id = tenant_id      # luôn cùng tenant

    # ==========================================
    # 📦 kiểm tra tồn kho
    # ==========================================
    total_qty = float(src["quantity"] or 0)
    used_now = await db.scalar(
        text("SELECT COALESCE(SUM(used_quantity),0) FROM batch_usages WHERE parent_batch_id=:pid"),
        {"pid": src["id"]},
    )
    used_now = float(used_now or 0.0)
    remaining = max(total_qty - used_now, 0.0)
    if remaining <= 0:
        raise HTTPException(400, "No remaining quantity to clone")

    # ==========================================
    # 🔧 chính sách tách (FULL/SPLIT)
    # ==========================================
    split_mode = await get_split_mode(db, batch_owner)
    is_full_transfer = (split_mode == "FULL")

    if is_full_transfer:
        used_qty = remaining
    else:
        if input_used <= 0:
            raise HTTPException(400, "used_quantity must be > 0")
        if input_used > remaining:
            raise HTTPException(400, f"Insufficient remaining quantity ({remaining})")
        used_qty = input_used

    # ==========================================
    # 🔄 đổi đơn vị nếu cần (Manufacturer)
    # ==========================================
    new_unit = src["unit"]
    new_quantity = used_qty

    if batch_owner == "manufacturer" and converted_unit and converted_rate:
        new_unit = converted_unit
        new_quantity = used_qty * float(converted_rate)

    # ==========================================
    # 🆕 tạo mã batch con
    # ==========================================
    new_code = f"{batch_code}-{next_role.upper()}-{datetime.now().strftime('%y%m%d-%H%M')}"

    # ==========================================
    # 🧾 INSERT batch con
    # (ghi chú quan trọng: tenant_id luôn = tenant hiện tại)
    # ==========================================
    await db.execute(text("""
        INSERT INTO batches (
            tenant_id, code, product_code, mfg_date, country,
            quantity, unit, status, material_type, description,
            owner_role, converted_from_unit, converted_rate, created_at
        )
        VALUES (:t_child, :code, :prod, :mfg, :country,
                :qty, :unit, 'OPEN', :mat, :desc,
                :role, :from_unit, :rate, NOW())
    """), {
        "t_child": child_tenant_id,          # 🔥 luôn tenant = user.tenant_id
        "code": new_code,
        "prod": src["product_code"],
        "mfg": src["mfg_date"],
        "country": src["country"],
        "qty": new_quantity,
        "unit": new_unit,
        "mat": src["material_type"],
        "desc": f"Cloned from {batch_code}",
        "role": next_role,                   # supplier / manufacturer / brand
        "from_unit": src["unit"],
        "rate": float(converted_rate or 1.0),
    })

    # ==========================================
    # 🔗 INSERT usage link
    # ==========================================
    await db.execute(text("""
        INSERT INTO batch_usages (parent_batch_id, child_batch_id, used_quantity, created_at)
        VALUES (:pid, (SELECT id FROM batches WHERE code=:code), :qty, NOW())
    """), {"pid": src["id"], "code": new_code, "qty": used_qty})

    # ==========================================
    # 📝 Audit log
    # ==========================================
    await db.execute(text("""
        INSERT INTO batch_clone_audit (
            actor, actor_role, ip_address,
            parent_batch_code, child_batch_code,
            used_quantity, unit
        )
        VALUES (:actor, :role, :ip, :pcode, :ccode, :qty, :unit)
    """), {
        "actor": user.get("email") or user.get("sub") or "unknown",
        "role": batch_owner,
        "ip": user.get("ip") or None,
        "pcode": batch_code,
        "ccode": new_code,
        "qty": used_qty,
        "unit": src["unit"],
    })

    # ==========================================
    # 🔚 cập nhật trạng thái batch cha
    # ==========================================
    used_after = await db.scalar(
        text("SELECT COALESCE(SUM(used_quantity),0) FROM batch_usages WHERE parent_batch_id=:pid"),
        {"pid": src["id"]},
    )
    used_after = float(used_after or 0.0)
    remaining_after = max(total_qty - used_after, 0.0)

    if remaining_after <= 0:
        await db.execute(text("UPDATE batches SET status='CLOSED' WHERE id=:pid"), {"pid": src["id"]})

    await db.commit()

    return {
        "ok": True,
        "new_code": new_code,
        "used_quantity": used_qty,
        "remaining_parent": remaining_after,
        "next_role": next_role,
        "tenant_id": child_tenant_id,      # luôn trả về tenant hiện tại
        "split_policy": split_mode,
        "converted_to": new_unit if new_unit != src["unit"] else None,
    }



# ============================================================
# ✅ GET: Usage log
# ============================================================
@router.get("/usage-log/{batch_id}")
async def get_usage_log(batch_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    tenant_id = user["tenant_id"]
    res = await db.execute(text("""
        SELECT u.id, u.used_quantity, u.unit, u.purpose, u.note, u.created_at, u.created_by,
               b2.code AS child_code
        FROM batch_usage_log u
        LEFT JOIN batches b2 ON u.child_batch_id = b2.id
        WHERE u.tenant_id=:t AND u.parent_batch_id=:pid
        ORDER BY u.created_at DESC
    """), {"t": tenant_id, "pid": batch_id})
    return {"items": [dict(r) for r in res.mappings().all()]}

# ============================================================
# ✅ GET: Trace tree trực quan Farm → Supplier → Manufacturer → Brand
# ============================================================
@router.get("/trace_tree/{batch_code}")
async def trace_tree(batch_code: str, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """Truy xuất cây batch cha – con"""
    q = await db.execute(text("SELECT id FROM batches WHERE code=:c"), {"c": batch_code})
    root = q.scalar()
    if not root:
        raise HTTPException(404, f"Batch {batch_code} not found")

    async def build(pid: int):
        res = await db.execute(text("""
            SELECT b.id, b.code, b.owner_role, b.quantity, b.used_quantity, b.unit,
                   (b.quantity - COALESCE(b.used_quantity,0)) AS remaining,
                   b.status
            FROM batches b
            WHERE b.id = :pid
        """), {"pid": pid})
        b = res.mappings().first()
        if not b:
            return None

        children = await db.execute(text("""
            SELECT c.id FROM batch_usages u
            JOIN batches c ON c.id = u.child_batch_id
            WHERE u.parent_batch_id = :pid
        """), {"pid": pid})
        child_ids = [r.id for r in children]
        return {
            "code": b["code"],
            "role": b["owner_role"],
            "quantity": float(b["quantity"] or 0),
            "used": float(b["used_quantity"] or 0),
            "remaining": float(b["remaining"] or 0),
            "status": b["status"],
            "unit": b["unit"] or "",
            "children": [await build(cid) for cid in child_ids],
        }

    return await build(root)

# ============================================================
# ✅ GET: Usage log
# ============================================================
@router.get("/usage-log/{batch_id}")
async def get_usage_log(batch_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    tenant_id = user["tenant_id"]
    res = await db.execute(text("""
        SELECT u.id, u.used_quantity, u.unit, u.purpose, u.note, u.created_at, u.created_by,
               b2.code AS child_code
        FROM batch_usage_log u
        LEFT JOIN batches b2 ON u.child_batch_id = b2.id
        WHERE u.tenant_id=:t AND u.parent_batch_id=:pid
        ORDER BY u.created_at DESC
    """), {"t": tenant_id, "pid": batch_id})
    return {"items": [dict(r) for r in res.mappings().all()]}

# ============================================================
# ✅ GET: Trace tree trực quan Farm → Supplier → Manufacturer → Brand
# ============================================================
@router.get("/trace_tree/{batch_code}")
async def trace_tree(batch_code: str, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """Truy xuất cây batch cha – con"""
    q = await db.execute(text("SELECT id FROM batches WHERE code=:c"), {"c": batch_code})
    root = q.scalar()
    if not root:
        raise HTTPException(404, f"Batch {batch_code} not found")

    async def build(pid: int):
        res = await db.execute(text("""
            SELECT b.id, b.code, b.owner_role, b.quantity, b.used_quantity, b.unit,
                   (b.quantity - COALESCE(b.used_quantity,0)) AS remaining,
                   b.status
            FROM batches b
            WHERE b.id = :pid
        """), {"pid": pid})
        b = res.mappings().first()
        if not b:
            return None

        children = await db.execute(text("""
            SELECT c.id FROM batch_usages u
            JOIN batches c ON c.id = u.child_batch_id
            WHERE u.parent_batch_id = :pid
        """), {"pid": pid})
        child_ids = [r.id for r in children]
        return {
            "code": b["code"],
            "role": b["owner_role"],
            "quantity": float(b["quantity"] or 0),
            "used": float(b["used_quantity"] or 0),
            "remaining": float(b["remaining"] or 0),
            "status": b["status"],
            "unit": b["unit"] or "",
            "children": [await build(cid) for cid in child_ids],
        }

    return await build(root)


# ============================================================
# ✅ GET: Get Usage summary (fixed by level)
# ============================================================
@router.get("/{batch_code}/usage_summary")
async def get_usage_summary(
    batch_code: str,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(403, "Unauthorized")

    try:
        # 🔹 1) Lấy batch info
        res = await db.execute(text("""
            SELECT id, quantity, unit, status
            FROM batches
            WHERE code = :c AND tenant_id = :t
            LIMIT 1
        """), {"c": batch_code, "t": tenant_id})
        b = res.mappings().first()
        if not b:
            raise HTTPException(404, f"Batch {batch_code} not found")

        pid = b["id"]
        total_qty = float(b["quantity"] or 0)

        # 🔹 2) Dùng cho clone (batch_usages)
        q1 = await db.execute(text("""
            SELECT COALESCE(SUM(u.used_quantity), 0)
            FROM batch_usages u
            WHERE u.parent_batch_id = :pid
        """), {"pid": pid})
        used_from_clone = float(q1.scalar() or 0)

        # 🔹 3) Dùng cho event (EPCIS)
        used_from_event = 0.0
        try:
            q2 = await db.execute(text("""
                SELECT COALESCE(SUM(e.used_quantity), 0)
                FROM epcis_events e
                WHERE e.batch_id = :pid
            """), {"pid": pid})
            used_from_event = float(q2.scalar() or 0)
        except Exception:
            # nếu bảng chưa có cột used_quantity hoặc chưa tồn tại
            await db.rollback()
            used_from_event = 0.0

        # 🔹 4) Dùng legacy batch_links (nếu còn)
        try:
            q3 = await db.execute(text("""
                SELECT COALESCE(SUM(l.material_used), 0)
                FROM batch_links l
                WHERE l.parent_batch_id = :pid
                  AND NOT EXISTS (
                      SELECT 1 FROM batch_usages u
                      WHERE u.parent_batch_id = :pid
                        AND u.child_batch_id = l.child_batch_id
                  )
            """), {"pid": pid})
            used_legacy = float(q3.scalar() or 0)
        except Exception as e:
            await db.rollback()
            print("⚠️ Legacy query failed:", e)
            used_legacy = 0.0

        total_used = used_from_clone + used_from_event + used_legacy
        remaining = max(total_qty - total_used, 0)

        return {
            "batch_code": batch_code,
            "status": b["status"],
            "unit": b["unit"] or "",
            "total": total_qty,
            "remaining": remaining,
            "used_from_clone": used_from_clone,
            "used_from_event": used_from_event,
            "used_legacy": used_legacy,
            "total_used": total_used,
        }

    except Exception as e:
        await db.rollback()
        print("❌ Error in usage_summary:", e)
        raise HTTPException(500, f"Error processing usage summary: {str(e)}")


# ============================================================
# ✅ DELETE: Rollback 1 lần clone (xoá lô con + usage)
# ============================================================
@router.delete("/rollback_clone")
async def rollback_clone(
    body: dict = Body(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    Xoá lô con được tạo bởi 'Clone to Next Level' và trừ lại used ở lô cha.
    body = { "child_code": "BATCH-XYZ-..." }
    """
    tenant_id = user.get("tenant_id")
    child_code = (body or {}).get("child_code")
    if not tenant_id or not child_code:
        raise HTTPException(400, "Missing tenant_id or child_code")

    # 🔎 tìm lô con
    res = await db.execute(text("""
        SELECT id FROM batches WHERE code=:c AND tenant_id=:t
    """), {"c": child_code, "t": tenant_id})
    child = res.mappings().first()
    if not child:
        raise HTTPException(404, f"Child batch {child_code} not found")

    child_id = child["id"]

    # ⛔ chặn nếu lô con đã tiếp tục sinh lô cháu
    cnt_down = await db.execute(text("""
        SELECT COUNT(*) FROM batch_usages WHERE parent_batch_id=:pid
    """), {"pid": child_id})
    if int(cnt_down.scalar() or 0) > 0:
        raise HTTPException(409, "Cannot rollback: child batch already used to create another batch")

    # 🔗 lấy bản ghi usage (ưu tiên bảng mới batch_usages, fallback batch_links)
    link = await db.execute(text("""
        SELECT id, parent_batch_id, used_quantity AS used
        FROM batch_usages
        WHERE child_batch_id=:cid
        LIMIT 1
    """), {"cid": child_id})
    usage = link.mappings().first()
    legacy = False
    if not usage:
        # dữ liệu cũ
        link2 = await db.execute(text("""
            SELECT id, parent_batch_id, material_used AS used
            FROM batch_links
            WHERE child_batch_id=:cid
            LIMIT 1
        """), {"cid": child_id})
        usage = link2.mappings().first()
        legacy = True

    if not usage:
        raise HTTPException(409, "No usage link found to rollback this child")

    parent_id = usage["parent_batch_id"]
    used = float(usage["used"] or 0)

    # ➖ trừ used cache ở lô cha (nếu có cột used_quantity)
    await db.execute(text("""
        UPDATE batches
        SET used_quantity = GREATEST(COALESCE(used_quantity,0) - :u, 0)
        WHERE id = :pid
    """), {"u": used, "pid": parent_id})

    # 🗑️ xoá link usage
    if legacy:
        await db.execute(text("DELETE FROM batch_links WHERE id=:id"), {"id": usage["id"]})
    else:
        await db.execute(text("DELETE FROM batch_usages WHERE id=:id"), {"id": usage["id"]})

    # 🗑️ xoá lô con
    await db.execute(text("""
        DELETE FROM batches WHERE id=:cid AND tenant_id=:t
    """), {"cid": child_id, "t": tenant_id})

    # ✅ commit tạm trước khi cập nhật lại status lô cha
    await db.commit()

    # 🔁 trả về summary mới của lô cha
    parent_info = await db.execute(text("""
        SELECT code, quantity, unit, status 
        FROM batches WHERE id=:id
    """), {"id": parent_id})
    p = parent_info.mappings().first() or {}

    # tổng used mới từ cả 2 bảng (tương thích dữ liệu cũ)
    used_sum = await db.execute(text("""
        SELECT
          COALESCE((SELECT SUM(used_quantity) FROM batch_usages WHERE parent_batch_id=:pid),0)
          +
          COALESCE((SELECT SUM(material_used) FROM batch_links WHERE parent_batch_id=:pid),0)
    """), {"pid": parent_id})
    used_total = float(used_sum.scalar() or 0)
    total_qty = float(p.get("quantity") or 0)
    unit = p.get("unit") or ""
    remaining = max(total_qty - used_total, 0)

    # 🔄 Nếu lô cha CLOSED mà giờ còn hàng -> reopen
    if remaining > 0 and (p.get("status") or "").upper() == "CLOSED":
        await db.execute(text("""
            UPDATE batches SET status='OPEN' WHERE id=:pid
        """), {"pid": parent_id})
        await db.commit()

    return {
        "ok": True,
        "rolled_child": child_code,
        "parent_code": p.get("code"),
        "summary": {
            "total": total_qty,
            "used": used_total,
            "remaining": remaining,
            "unit": unit,
            "parent_status": "OPEN" if remaining > 0 else (p.get("status") or "OPEN"),
        },
    }


# ============================================================
# ✅ DELETE: Force delete batch (bao gồm mọi usage & link liên quan)
# ============================================================
@router.delete("/{batch_id}/force_delete")
async def force_delete_batch(
    batch_id: int,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    Xóa hoàn toàn batch và toàn bộ dữ liệu liên kết:
    - batch_usages (cả chiều parent & child)
    - batch_links (cả chiều parent & child)
    - Không kiểm tra quyền: chỉ cần có tenant_id (cho phép admin & useradmin)
    """
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(403, "Unauthorized")

    # Kiểm tra tồn tại
    res = await db.execute(
        text("SELECT id, code FROM batches WHERE id=:id AND tenant_id=:t"),
        {"id": batch_id, "t": tenant_id},
    )
    b = res.mappings().first()
    if not b:
        raise HTTPException(404, f"Batch id={batch_id} not found")

    code = b["code"]

    try:
        # 🔹 Xóa mọi batch_usages có liên quan (cả parent & child)
        await db.execute(
            text("""
                DELETE FROM batch_usages
                WHERE parent_batch_id=:id OR child_batch_id=:id
            """),
            {"id": batch_id},
        )

        # 🔹 Xóa mọi batch_links (legacy)
        await db.execute(
            text("""
                DELETE FROM batch_links
                WHERE parent_batch_id=:id OR child_batch_id=:id
            """),
            {"id": batch_id},
        )

        # 🔹 Xóa logs nếu có
        await db.execute(
            text("""
                DELETE FROM batch_usage_log
                WHERE parent_batch_id=:id OR child_batch_id=:id
            """),
            {"id": batch_id},
        )

        # 🔹 Xóa luôn batch
        await db.execute(
            text("DELETE FROM batches WHERE id=:id AND tenant_id=:t"),
            {"id": batch_id, "t": tenant_id},
        )

        await db.commit()

        return {"ok": True, "message": f"Batch {code} and all related usages deleted"}

    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"Delete failed: {str(e)}")



@router.delete("/rollback_clone")
async def rollback_clone(
    body: dict = Body(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    Rollback một lần clone:
    - Xoá lô con (child batch) được tạo bởi Clone to Next Level
    - Xoá bản ghi usage/link giữa parent-child
    - Cập nhật lại used/remaining và status cho lô cha
    ---
    Body:
      {
        "child_code": "BATCH-ABC-...-SUPPLIER-250311-1105"
      }
    """
    tenant_id = user.get("tenant_id")
    child_code = (body or {}).get("child_code")

    if not tenant_id or not child_code:
        raise HTTPException(400, "Missing tenant_id or child_code")

    # 1) Tìm lô con theo code
    res = await db.execute(
        text("SELECT id FROM batches WHERE code=:c AND tenant_id=:t"),
        {"c": child_code, "t": tenant_id},
    )
    child = res.mappings().first()
    if not child:
        raise HTTPException(404, f"Child batch {child_code} not found")

    child_id = child["id"]

    # 2) Chặn rollback nếu lô con đã sinh ra lô cháu
    has_grandchildren = await db.execute(
        text("SELECT COUNT(*) FROM batch_usages WHERE parent_batch_id=:pid"),
        {"pid": child_id},
    )
    if int(has_grandchildren.scalar() or 0) > 0:
        raise HTTPException(
            409,
            "Cannot rollback: child batch already used to create another batch",
        )

    # 3) Lấy link usage giữa parent-child (ưu tiên batch_usages, nếu không có dùng legacy batch_links)
    link = await db.execute(
        text("""
            SELECT id, parent_batch_id, used_quantity AS used
            FROM batch_usages
            WHERE child_batch_id=:cid
            LIMIT 1
        """),
        {"cid": child_id},
    )
    usage = link.mappings().first()
    legacy = False

    if not usage:
        link2 = await db.execute(
            text("""
                SELECT id, parent_batch_id, material_used AS used
                FROM batch_links
                WHERE child_batch_id=:cid
                LIMIT 1
            """),
            {"cid": child_id},
        )
        usage = link2.mappings().first()
        legacy = True

    if not usage:
        raise HTTPException(409, "No usage link found to rollback this child")

    parent_id = usage["parent_batch_id"]
    used_amount = float(usage["used"] or 0.0)

    # 4) (Tuỳ chọn) Cập nhật cache used_quantity ở lô cha nếu bạn có cột này
    #    Ở nhiều schema không có cột used_quantity trong bảng batches nên bước này có thể bỏ qua
    await db.execute(
        text("""
            UPDATE batches
            SET used_quantity = GREATEST(COALESCE(used_quantity,0) - :u, 0)
            WHERE id = :pid
        """),
        {"u": used_amount, "pid": parent_id},
    )

    # 5) Xoá usage link
    if legacy:
        await db.execute(text("DELETE FROM batch_links WHERE id=:id"), {"id": usage["id"]})
    else:
        await db.execute(text("DELETE FROM batch_usages WHERE id=:id"), {"id": usage["id"]})

    # 6) Xoá lô con
    await db.execute(
        text("DELETE FROM batches WHERE id=:cid AND tenant_id=:t"),
        {"cid": child_id, "t": tenant_id},
    )

    # 7) Tính lại tồn của lô cha & mở lại nếu cần
    #    (tổng used = batch_usages + batch_links để tương thích dữ liệu cũ)
    used_sum = await db.execute(
        text("""
            SELECT
              COALESCE((
                SELECT SUM(used_quantity) FROM batch_usages WHERE parent_batch_id=:pid
              ),0)
              +
              COALESCE((
                SELECT SUM(material_used) FROM batch_links WHERE parent_batch_id=:pid
              ),0)
        """),
        {"pid": parent_id},
    )
    used_total = float(used_sum.scalar() or 0.0)

    parent_info = await db.execute(
        text("SELECT code, quantity, unit, status FROM batches WHERE id=:id"),
        {"id": parent_id},
    )
    p = parent_info.mappings().first() or {}
    total_qty = float(p.get("quantity") or 0.0)
    remaining = max(total_qty - used_total, 0.0)

    # Nếu trước đó bị CLOSED vì hết hàng, giờ hoàn mở lại nếu còn hàng
    if remaining > 0 and (p.get("status") or "").upper() == "CLOSED":
        await db.execute(
            text("UPDATE batches SET status='OPEN' WHERE id=:pid"),
            {"pid": parent_id},
        )

    await db.commit()

    return {
        "ok": True,
        "rolled_child": child_code,
        "parent_code": p.get("code"),
        "summary": {
            "total": total_qty,
            "used": used_total,
            "remaining": remaining,
            "unit": p.get("unit") or "",
            "parent_status": "OPEN" if remaining > 0 else (p.get("status") or "OPEN"),
        },
    }