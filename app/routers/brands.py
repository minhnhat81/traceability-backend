from fastapi import APIRouter, Depends, HTTPException
from app.utils.pagination import Page, PageMeta
from sqlalchemy.orm import Session
from sqlalchemy import select
from app.core.db import get_db
from app.models.brand import Brand
from app.schemas.brand import BrandCreate, BrandOut
from .crud_utils import paginate_query, like_filters

router = APIRouter(prefix="/api/brands", tags=["brands"])

@router.get("", response_model=list[BrandOut])
def list_brands(page: int = 1, size: int = 10, q: str | None = None, db: Session = Depends(get_db)):
    stmt = select(Brand)
    cond = like_filters(Brand, q or "", ["name", "owner", "website"])
    if cond is not None: stmt = stmt.where(cond)
    stmt = stmt.order_by(Brand.id.desc())
    return list(db.execute(paginate_query(stmt, page, size)).scalars())

@router.post("", response_model=BrandOut, status_code=201)
def create_brand(payload: BrandCreate, db: Session = Depends(get_db)):
    if db.query(Brand).filter_by(name=payload.name).first():
        raise HTTPException(400, "Brand name already exists")
    obj = Brand(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return obj

@router.put("/{id}", response_model=BrandOut)
def update_brand(id: int, payload: BrandCreate, db: Session = Depends(get_db)):
    obj = db.get(Brand, id)
    if not obj: raise HTTPException(404)
    for k,v in payload.model_dump().items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return obj

@router.delete("/{id}", status_code=204)
def delete_brand(id: int, db: Session = Depends(get_db)):
    obj = db.get(Brand, id)
    if not obj: raise HTTPException(404)
    db.delete(obj); db.commit()
    return None
