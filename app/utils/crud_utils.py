from sqlalchemy import or_
from sqlalchemy.sql import Select

def like_filters(model, q: str, fields: list[str]):
    """Tạo điều kiện LIKE cho nhiều cột khi tìm kiếm."""
    if not q:
        return None
    conditions = []
    for f in fields:
        col = getattr(model, f, None)
        if col is not None:
            conditions.append(col.ilike(f"%{q}%"))
    if not conditions:
        return None
    return or_(*conditions)


def paginate_query(stmt: Select, page: int, size: int):
    """Thêm offset và limit vào query"""
    offset = (page - 1) * size
    return stmt.offset(offset).limit(size)
