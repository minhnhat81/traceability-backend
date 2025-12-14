from pydantic import BaseModel
from datetime import datetime
from typing import Any
from .common import Orm

class EventCreate(BaseModel):
    batch_code: str
    product_code: str
    event_time: datetime | None = None
    biz_step: str | None = None
    disposition: str | None = None
    data: dict[str, Any] | None = None

class EventOut(Orm):
    id: int
    batch_code: str
    product_code: str
    event_time: datetime | None = None
    biz_step: str | None = None
    disposition: str | None = None
    data: dict | None = None
