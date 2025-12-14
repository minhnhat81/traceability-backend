from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.db import get_db
from app.models.dpp_template import DppTemplate
from app.schemas.dpp_template import DppTemplateCreate, DppTemplateUpdate, DppTemplateOut
from app.security import verify_jwt
import json

router = APIRouter(prefix="/api/dpp-templates", tags=["dpp-templates"])


# =========================
# 🔍 GET /api/dpp-templates
# =========================
@router.get("/", response_model=list[DppTemplateOut])
async def list_templates(
    q: str | None = Query(None, description="Search by name"),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    try:
        tenant_id = (
            user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
        )
        if tenant_id is None:
            raise HTTPException(400, "Missing tenant_id in token context")

        stmt = select(DppTemplate).where(DppTemplate.tenant_id == tenant_id)
        if q:
            stmt = stmt.filter(DppTemplate.name.ilike(f"%{q}%"))
        stmt = stmt.order_by(DppTemplate.created_at.desc())

        result = await db.execute(stmt)
        templates = result.scalars().all()

        # Đảm bảo dữ liệu JSON hóa được
        cleaned = []
        for t in templates:
            cleaned.append({
                "id": t.id,
                "tenant_id": t.tenant_id,  # ✅ thêm dòng này
                "name": t.name,
                "description": getattr(t, "description", None),
                "schema": t.schema if isinstance(t.schema, dict) else {},
                "static_data": t.static_data if isinstance(t.static_data, dict) else {},
                "dynamic_data": t.dynamic_data if isinstance(t.dynamic_data, dict) else {},
                "created_at": str(t.created_at),
            })


        return cleaned

    except Exception as e:
        import traceback
        print("🔥 DPP list_templates error:", traceback.format_exc())
        raise HTTPException(500, f"Server error: {e}")



# ===============================
# 🔍 GET /api/dpp-templates/{id}
# ===============================
@router.get("/{tpl_id}", response_model=DppTemplateOut)
async def get_template(tpl_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    tenant_id = user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
    if tenant_id is None:
        raise HTTPException(400, "Missing tenant_id in token context")

    tpl = await db.get(DppTemplate, tpl_id)
    if not tpl or tpl.tenant_id != tenant_id:
        raise HTTPException(404, "Template not found")

    return tpl


# ==============================
# ➕ POST /api/dpp-templates
# ==============================
@router.post("/", response_model=DppTemplateOut)
async def create_template(payload: DppTemplateCreate, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    tenant_id = user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
    if tenant_id is None:
        raise HTTPException(400, "Missing tenant_id in token context")

    data = payload.dict(exclude_unset=True)
    data.pop("tenant_id", None)

    # ✅ Parse string JSON cho các field schema, static_data, dynamic_data
    for field in ["schema", "static_data", "dynamic_data"]:
        value = data.get(field)
        if isinstance(value, str):
            try:
                data[field] = json.loads(value)
            except Exception:
                raise HTTPException(
                    400, f"Invalid JSON format in field '{field}'. Please provide valid JSON."
                )

    tpl = DppTemplate(**data, tenant_id=tenant_id)
    db.add(tpl)
    await db.commit()
    await db.refresh(tpl)
    return tpl


# ===============================
# ✏️ PUT /api/dpp-templates/{id}
# ===============================
@router.put("/{tpl_id}", response_model=DppTemplateOut)
async def update_template(
    tpl_id: int,
    payload: DppTemplateUpdate,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
    if tenant_id is None:
        raise HTTPException(400, "Missing tenant_id in token context")

    tpl = await db.get(DppTemplate, tpl_id)
    if not tpl or tpl.tenant_id != tenant_id:
        raise HTTPException(404, "Template not found")

    data = payload.dict(exclude_unset=True)
    for field in ["schema", "static_data", "dynamic_data"]:
        value = data.get(field)
        if isinstance(value, str):
            try:
                data[field] = json.loads(value)
            except Exception:
                raise HTTPException(400, f"Invalid JSON format in field '{field}'.")

    for k, v in data.items():
        setattr(tpl, k, v)

    await db.commit()
    await db.refresh(tpl)
    return tpl


# ===============================
# ❌ DELETE /api/dpp-templates/{id}
# ===============================
@router.delete("/{tpl_id}")
async def delete_template(tpl_id: int, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    tenant_id = user.get("tenant_id") if isinstance(user, dict) else getattr(user, "tenant_id", None)
    if tenant_id is None:
        raise HTTPException(400, "Missing tenant_id in token context")

    tpl = await db.get(DppTemplate, tpl_id)
    if not tpl or tpl.tenant_id != tenant_id:
        raise HTTPException(404, "Template not found")

    await db.delete(tpl)
    await db.commit()
    return {"ok": True}
