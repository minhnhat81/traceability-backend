from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.db import get_db
from app.models.farm import Farm
from app.schemas.farm import FarmCreate, FarmRead, FarmUpdate
from app.security import verify_jwt

router = APIRouter(prefix="/api/farms", tags=["farms"])

# -----------------------------
# 🟢 Create new farm
# -----------------------------
@router.post("", response_model=FarmRead)
async def create_farm(payload: FarmCreate, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    if not user or "tenant_id" not in user:
        raise HTTPException(status_code=403, detail="unauthorized or missing tenant_id")

    farm = Farm(**payload.model_dump())
    farm.tenant_id = user["tenant_id"]
    db.add(farm)
    await db.commit()
    await db.refresh(farm)
    return FarmRead.model_validate(farm)


# -----------------------------
# 🔵 List all farms (GET)
# -----------------------------
@router.get("/")
async def list_farms(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    if not user or "tenant_id" not in user:
        raise HTTPException(403, "unauthorized or missing tenant_id")
    tenant_id = user["tenant_id"]

    result = await db.execute(
        text("""
            SELECT id, name, code, location, size_ha, certification, contact_info,
                   farm_type, status, created_at
            FROM farms
            WHERE tenant_id = :t OR tenant_id IS NULL
            ORDER BY id DESC
        """),
        {"t": tenant_id},
    )
    rows = result.mappings().all()
    return {"items": rows}


# -----------------------------
# 🟣 List farms (GET + POST /list) — dùng cho frontend cũ
# -----------------------------
@router.get("/list")
@router.post("/list")
async def list_farms_list(db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    Cho phép cả GET và POST /api/farms/list — tương thích frontend cũ và mới
    """
    if not user or "tenant_id" not in user:
        raise HTTPException(403, "unauthorized or missing tenant_id")
    tenant_id = user["tenant_id"]

    result = await db.execute(
        text("""
            SELECT id, name, code, location, size_ha, certification, contact_info,
                   farm_type, status, created_at
            FROM farms
            WHERE tenant_id = :t OR tenant_id IS NULL
            ORDER BY id DESC
        """),
        {"t": tenant_id},
    )
    rows = result.mappings().all()
    return {"items": rows}


# -----------------------------
# 🟣 Get single farm
# -----------------------------
@router.get("/{id}", response_model=FarmRead)
async def get_farm(id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    farm = await db.get(Farm, id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    return FarmRead.model_validate(farm)


# -----------------------------
# 🟠 Update farm
# -----------------------------
@router.put("/{id}", response_model=FarmRead)
async def update_farm(id: int, payload: FarmUpdate, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    farm = await db.get(Farm, id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(farm, key, value)

    db.add(farm)
    await db.commit()
    await db.refresh(farm)
    return FarmRead.model_validate(farm)


# -----------------------------
# 🔴 Delete farm
# -----------------------------
@router.delete("/{id}", status_code=204)
async def delete_farm(id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    farm = await db.get(Farm, id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")

    await db.delete(farm)
    await db.commit()
