from __future__ import annotations
from typing import Optional, List
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.db import Base

class ComplianceResult(Base):
    __tablename__ = "compliance_results"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))
    batch_code: Mapped[Optional[str]] = mapped_column(String(64))
    scheme: Mapped[Optional[str]] = mapped_column(String(64))
    pass_flag: Mapped[Optional[bool]] = mapped_column(Boolean)
    details: Mapped[Optional[dict]] = mapped_column(JSONB)

    tenant = relationship("Tenant", back_populates="compliance_results", lazy="selectin")
