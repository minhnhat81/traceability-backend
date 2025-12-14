from __future__ import annotations
from typing import Optional, List, Any
from pydantic import BaseModel
from datetime import datetime

class SensorEventBase(BaseModel):
    pass

class SensorEventCreate(SensorEventBase):
    epcis_event_id: Optional[int] = None
    sensor_meta: Optional[dict] = None
    sensor_reports: Optional[dict] = None

class SensorEventOut(SensorEventBase):
    id: int
    epcis_event_id: Optional[int] = None
    sensor_meta: Optional[dict] = None
    sensor_reports: Optional[dict] = None
