from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.db import get_db
from app.security import verify_jwt
import logging

logger = logging.getLogger("uvicorn")

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])


@router.get("/summary")
async def summary(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ✅ Endpoint mới /api/dashboard/summary
    Trả về tổng quan dữ liệu dashboard cho người dùng sau khi đăng nhập.
    """

    # --- Các truy vấn đếm tổng ---
    async def q_async(sql: str) -> int:
        try:
            result = await db.execute(text(sql))
            val = result.scalar()
            return int(val or 0)
        except Exception as e:
            logger.error(f"[DASHBOARD SQL ERROR] {sql} → {e}")
            await db.rollback()
            return 0

    # --- Truy vấn thống kê theo quốc gia ---
    async def q_rows():
        try:
            result = await db.execute(
                text("""
                    SELECT country, COUNT(*) 
                    FROM batches 
                    GROUP BY country 
                    ORDER BY COUNT(*) DESC 
                    LIMIT 10
                """)
            )
            return result.fetchall()
        except Exception as e:
            logger.error(f"[DASHBOARD SQL ERROR] country stats → {e}")
            await db.rollback()
            return []

    # --- Thực thi tuần tự (async await) ---
    counts = {
        "products": await q_async("SELECT COUNT(*) FROM products"),
        "batches": await q_async("SELECT COUNT(*) FROM batches"),
        "suppliers": await q_async("SELECT COUNT(*) FROM suppliers"),
        "events": await q_async("SELECT COUNT(*) FROM epcis_events"),
        "documents": await q_async("SELECT COUNT(*) FROM documents"),
        "credentials": await q_async("SELECT COUNT(*) FROM credentials"),
    }

    rows = await q_rows()
    stats = []
    if rows:
        for r in rows:
            country = str(r[0]) if r[0] is not None else "Unknown"
            count = int(r[1]) if r[1] is not None else 0
            stats.append({"country": country, "count": count})

    # --- Trả về kết quả JSON ---
    return {
        "ok": True,
        "summary": dict(counts),
        "stats": stats,
        "user": {
            "username": str(user.get("username")),
            "role": str(user.get("role")),
            "tenant_id": int(user.get("tenant_id", 1)),
        },
    }
