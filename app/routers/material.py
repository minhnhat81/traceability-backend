# app/routers/material.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete
from typing import List
from app.core.db import get_db
from app.models.material import Material
from app.schemas.material import MaterialCreate, MaterialRead, MaterialUpdate

router = APIRouter(prefix="/materials", tags=["Materials"])

# ==========================================================
# 🧩 Lấy danh sách materials (theo tenant)
# ==========================================================
@router.get("/", response_model=List[MaterialRead])
async def get_materials(tenant_id: int, db: AsyncSession = Depends(get_db)):
    query = select(Material).where(Material.tenant_id == tenant_id)
    result = await db.execute(query)
    return result.scalars().all()

# ==========================================================
# ➕ Tạo material mới
# ==========================================================
@router.post("/", response_model=MaterialRead)
async def create_material(material_in: MaterialCreate, db: AsyncSession = Depends(get_db)):
    new_material = Material(**material_in.model_dump())
    db.add(new_material)
    await db.commit()
    await db.refresh(new_material)
    return new_material

# ==========================================================
# 🔧 Cập nhật material
# ==========================================================
@router.put("/{material_id}", response_model=MaterialRead)
async def update_material(
    material_id: int,
    material_in: MaterialUpdate,
    tenant_id: int,
    db: AsyncSession = Depends(get_db),
):
    query = select(Material).where(
        Material.id == material_id, Material.tenant_id == tenant_id
    )
    result = await db.execute(query)
    material = result.scalars().first()

    if not material:
        raise HTTPException(status_code=404, detail="Material not found")

    for key, value in material_in.model_dump(exclude_unset=True).items():
        setattr(material, key, value)

    await db.commit()
    await db.refresh(material)
    return material

# ==========================================================
# ❌ Xóa material
# ==========================================================
@router.delete("/{material_id}")
async def delete_material(material_id: int, tenant_id: int, db: AsyncSession = Depends(get_db)):
    query = select(Material).where(
        Material.id == material_id, Material.tenant_id == tenant_id
    )
    result = await db.execute(query)
    material = result.scalars().first()

    if not material:
        raise HTTPException(status_code=404, detail="Material not found")

    await db.delete(material)
    await db.commit()
    return {"message": "Material deleted successfully"}
