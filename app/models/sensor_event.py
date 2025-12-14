from __future__ import annotations
from typing import Optional, List
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.db import Base

class SensorEvent(Base):
    __tablename__ = "sensor_events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    epcis_event_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("epcis_events.id"))
    sensor_meta: Mapped[Optional[dict]] = mapped_column(JSONB)
    sensor_reports: Mapped[Optional[dict]] = mapped_column(JSONB)

    epcis_event = relationship("EpcisEvent", back_populates="sensor_events", lazy="selectin")
