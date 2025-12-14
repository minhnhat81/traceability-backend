from pydantic import BaseModel
from .common import Orm

class CustomerCreate(BaseModel):
    code: str
    name: str
    country: str | None = None
    contact_email: str | None = None

class CustomerOut(Orm):
    id: int
    code: str
    name: str
    country: str | None = None
    contact_email: str | None = None
