from __future__ import annotations
from typing import Optional, List
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.db import Base

class DataSharingAgreement(Base):
    __tablename__ = "data_sharing_agreements"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))
    partner: Mapped[Optional[str]] = mapped_column(String(255))
    scope: Mapped[Optional[dict]] = mapped_column(JSONB)
    terms: Mapped[Optional[dict]] = mapped_column(JSONB)

    tenant = relationship("Tenant", back_populates="data_sharing_agreements", lazy="selectin")
