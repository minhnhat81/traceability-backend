from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from datetime import datetime
from app.core.db import get_db
from app.security import verify_jwt

router = APIRouter(prefix="/api/batch-links", tags=["Batch Links"])


# ==========================================================
# ✅ POST /api/batch-links/  → Tạo liên kết cha–con
# ==========================================================
@router.post("/")
async def create_batch_link(payload: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    Tạo liên kết giữa 2 lô (cha → con)
    - parent_batch_id: ID lô cha
    - child_batch_id: ID lô con
    - material_used: số lượng sử dụng
    - unit: đơn vị (mặc định theo lô cha)
    """
    parent_id = payload.get("parent_batch_id")
    child_id = payload.get("child_batch_id")
    material_used = payload.get("material_used", 0)
    unit = payload.get("unit", "kg")

    if not parent_id or not child_id:
        raise HTTPException(400, "parent_batch_id and child_batch_id are required")

    # kiểm tra trùng
    check_query = text("""
        SELECT id FROM batch_links
        WHERE parent_batch_id=:p AND child_batch_id=:c
    """)
    res = await db.execute(check_query, {"p": parent_id, "c": child_id})
    if res.scalar():
        raise HTTPException(409, "This batch link already exists")

    insert_q = text("""
        INSERT INTO batch_links (parent_batch_id, child_batch_id, material_used, unit, created_at)
        VALUES (:p, :c, :m, :u, :t)
        RETURNING id
    """)
    result = await db.execute(insert_q, {
        "p": parent_id, "c": child_id,
        "m": material_used, "u": unit,
        "t": datetime.utcnow()
    })
    await db.commit()
    new_id = result.scalar()

    return {"id": new_id, "message": "Batch link created successfully"}


# ==========================================================
# ✅ GET /api/batch-links/chain/{batch_id}  → Truy xuất chuỗi nguồn gốc
# ==========================================================
@router.get("/chain/{batch_id}")
async def get_batch_chain(batch_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    Truy xuất chuỗi upstream từ lô hiện tại.
    Kết quả: [Brand → Manufacturer → Supplier → Farm]
    """
    query = text("""
        WITH RECURSIVE chain AS (
            SELECT b.id, b.code, b.product_code, b.owner_role, b.quantity, b.unit, b.material_type,
                   b.created_at, b.description, NULL::INT AS parent_id
            FROM batches b
            WHERE b.id = :batch_id
            UNION ALL
            SELECT p.id, p.code, p.product_code, p.owner_role, p.quantity, p.unit, p.material_type,
                   p.created_at, p.description, bl.parent_batch_id
            FROM batches p
            JOIN batch_links bl ON bl.parent_batch_id = p.id
            JOIN chain c ON c.id = bl.child_batch_id
        )
        SELECT * FROM chain;
    """)
    result = await db.execute(query, {"batch_id": batch_id})
    rows = result.fetchall()

    chain = []
    for r in rows:
        chain.append({
            "id": r.id,
            "code": r.code,
            "owner_role": r.owner_role,
            "quantity": float(r.quantity or 0),
            "unit": r.unit or "",
            "material_type": r.material_type,
            "description": r.description,
            "created_at": (
                r.created_at.strftime("%Y-%m-%d %H:%M:%S")
                if r.created_at else ""
            )
        })
    return {"chain": chain}
