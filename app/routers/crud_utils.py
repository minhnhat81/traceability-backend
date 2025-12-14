from sqlalchemy import func
from typing import Type, Any
from sqlalchemy.orm import Session
from sqlalchemy import select, or_
from fastapi import Query
from app.utils.pagination import Page, PageMeta

def paginate_query(stmt, page: int = 1, size: int = 10):
    offset = max(page-1, 0) * max(size, 1)
    return stmt.offset(offset).limit(size)

def like_filters(model, q: str, columns: list[str]):
    if not q:
        return None
    conds = []
    for col in columns:
        if hasattr(model, col):
            conds.append(getattr(model, col).ilike(f"%{q}%"))
    from sqlalchemy import or_
    return or_(*conds) if conds else None
