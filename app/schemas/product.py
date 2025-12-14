from pydantic import BaseModel
from .common import Orm

class ProductCreate(BaseModel):
    code: str
    name: str
    category: str | None = None

class ProductOut(Orm):
    id: int
    code: str
    name: str
    category: str | None = None
