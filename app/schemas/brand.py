from pydantic import BaseModel
from .common import Orm

class BrandCreate(BaseModel):
    name: str
    owner: str | None = None
    website: str | None = None

class BrandOut(Orm):
    id: int
    name: str
    owner: str | None = None
    website: str | None = None
