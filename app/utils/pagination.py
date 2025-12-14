from typing import Generic, List, Sequence, Tuple, TypeVar
from pydantic.generics import GenericModel
from pydantic import BaseModel
from sqlalchemy import func, Select
from sqlalchemy.ext.asyncio import AsyncSession  # ✅ dùng đúng kiểu async

T = TypeVar('T')


class PageMeta(BaseModel):
    total: int
    limit: int
    offset: int


class Page(GenericModel, Generic[T]):
    data: List[T]
    meta: PageMeta


# ✅ Sửa hàm sang async để có thể dùng await
async def paginate_select(
    session: AsyncSession,
    select_stmt: Select,
    limit: int,
    offset: int
) -> Tuple[Sequence, int]:
    # Đếm tổng số dòng
    total_result = await session.execute(
        select_stmt.with_only_columns(func.count()).order_by(None)
    )
    total = total_result.scalar_one()

    # Lấy dữ liệu phân trang
    rows_result = await session.execute(
        select_stmt.limit(limit).offset(offset)
    )
    rows = rows_result.scalars().all()

    return rows, total
