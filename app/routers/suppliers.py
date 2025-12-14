from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.db import get_db
from app.models.supplier import Supplier
from app.schemas.supplier import SupplierCreate, SupplierUpdate, SupplierOut
from app.security import verify_jwt

router = APIRouter(prefix="/api/suppliers", tags=["suppliers"])



# ============================================================
# 📌 GET /api/suppliers/options — dropdown (farm/batch dùng)
# ============================================================
@router.get("", response_model=list[SupplierOut])
async def list_suppliers(
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
    q: str | None = Query(None, description="Search keyword"),
):
    tenant_id = user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
    if tenant_id is not None:
        tenant_id = int(tenant_id)
        print(f"[DEBUG] tenant_id={tenant_id}")

    stmt = select(Supplier).where(Supplier.tenant_id == tenant_id)
    if q:
        stmt = stmt.where(Supplier.name.ilike(f"%{q}%"))

    result = await db.execute(stmt)
    return result.scalars().all()


# ============================================================
# 📋 GET /api/suppliers — list all
# ============================================================

@router.get("", response_model=list[SupplierOut])
async def list_suppliers(
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
    q: str | None = Query(None, description="Search keyword"),
):
    tenant_id = getattr(user, "tenant_id", None)
    # ép kiểu chắc chắn integer
    if tenant_id is not None:
        tenant_id = int(tenant_id)
        print(f"[DEBUG] tenant_id={tenant_id}")

    stmt = select(Supplier).where(Supplier.tenant_id == tenant_id)
    if q:
        stmt = stmt.where(Supplier.name.ilike(f"%{q}%"))

    result = await db.execute(stmt)
    return result.scalars().all()

# ============================================================
# ➕ POST /api/suppliers — create
# ============================================================
@router.post("", response_model=SupplierOut)
async def create_supplier(
    payload: SupplierCreate,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    # Lấy tenant_id linh hoạt
    tenant_id = user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
    if tenant_id is None:
        raise HTTPException(400, "Missing tenant_id in token context")

    # Kiểm tra trùng mã
    exists = await db.execute(
        select(Supplier).where(Supplier.code == payload.code, Supplier.tenant_id == tenant_id)
    )
    if exists.scalars().first():
        raise HTTPException(400, "Supplier code already exists")

    new_supplier = Supplier(
        tenant_id=tenant_id,
        code=payload.code,
        name=payload.name,
        country=payload.country,
        contact_email=payload.contact_email,
        phone=payload.phone,
        address=payload.address,
        factory_location=payload.factory_location,
        certification=payload.certification,
        user_id=payload.user_id,
    )
    db.add(new_supplier)
    await db.commit()
    await db.refresh(new_supplier)
    return new_supplier


# ============================================================
# ✏️ PUT /api/suppliers/{id}
# ============================================================
@router.put("/{id}", response_model=SupplierOut)
async def update_supplier(
    id: int,
    payload: SupplierUpdate,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
  
    tenant_id = user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
    if tenant_id is None:
        raise HTTPException(400, "Missing tenant_id in token context")


    supplier = await db.get(Supplier, id)
    if not supplier or supplier.tenant_id != tenant_id:
        raise HTTPException(404, "Supplier not found")

    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(supplier, k, v)
    await db.commit()
    await db.refresh(supplier)
    return supplier

# ============================================================
# ❌ DELETE /api/suppliers/{id}
# ============================================================
@router.delete("/{id}", status_code=204)
async def delete_supplier(
    id: int,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = getattr(user, "tenant_id", None)
    supplier = await db.get(Supplier, id)
    if not supplier or supplier.tenant_id != tenant_id:
        raise HTTPException(404, "Supplier not found")

    await db.delete(supplier)
    await db.commit()
    return

# ============================================================
# 🔍 GET /api/suppliers/{id}
# ============================================================
@router.get("/{id}", response_model=SupplierOut)
async def get_supplier(
    id: int,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = getattr(user, "tenant_id", None)
    supplier = await db.get(Supplier, id)
    if not supplier or supplier.tenant_id != tenant_id:
        raise HTTPException(404, "Supplier not found")
    return supplier
