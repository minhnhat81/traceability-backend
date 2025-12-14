from sqlalchemy import select
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.utils.pagination import Page, PageMeta
from app.core.db import get_db
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductOut

router = APIRouter(prefix="/api/products", tags=["products"])


@router.get("", response_model=list[ProductOut])
async def list_products(
    db: AsyncSession = Depends(get_db),
    tenant_id: int | None = None,
    material_id: int | None = None,
    category: str | None = None,
    limit: int = 50,
    offset: int = 0,
):
    """
    ✅ Lấy danh sách sản phẩm (lọc theo tenant/material/category)
    """
    stmt = select(Product)
    if tenant_id:
        stmt = stmt.where(Product.tenant_id == tenant_id)
    if material_id:
        stmt = stmt.where(Product.material_id == material_id)
    if category:
        stmt = stmt.where(Product.category == category)

    stmt = stmt.order_by(Product.id.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    return result.scalars().all()



@router.post("", response_model=ProductOut, status_code=201)
async def create_product(payload: ProductCreate, db: AsyncSession = Depends(get_db)):
    """
    ✅ Tạo sản phẩm mới (async)
    """
    # Kiểm tra trùng code
    check = await db.execute(select(Product).where(Product.code == payload.code))
    existing = check.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Product code already exists")

    # Tạo mới
    obj = Product(
        code=payload.code,
        name=payload.name,
        category=payload.category,
    )

    db.add(obj)
    await db.commit()
    await db.refresh(obj)

    return obj
