from pydantic import BaseModel
from .common import Orm


# ----- Input khi tạo user -----
class UserCreate(BaseModel):
    username: str | None = None     # Cho phép None → backend tự tạo từ email
    name: str | None = None
    email: str
    role: str | None = "supplier"
    tenant_id: int | None = None
    is_active: bool | None = True


# ----- Output khi trả về user -----
class UserOut(Orm):
    id: int
    username: str
    name: str | None = None
    email: str | None = None
    role: str | None = None
    tenant_id: int | None = None
    is_active: bool | None = True
