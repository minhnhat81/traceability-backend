# traceability/backend/app/models/dpp_template.py
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from sqlalchemy import Integer, String, Boolean, ForeignKey, Text, DateTime
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.db import Base

class DppTemplate(Base):
    __tablename__ = "dpp_templates"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    schema: Mapped[Dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict)
    tenant_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tenants.id", ondelete="CASCADE"))
    tier: Mapped[str] = mapped_column(String(32), default="supplier", nullable=False)
    template_name: Mapped[str] = mapped_column(String(128), default="default", nullable=False)
    static_data: Mapped[Dict[str, Any]] = mapped_column(JSONB, default=dict)
    dynamic_data: Mapped[Dict[str, Any]] = mapped_column(JSONB, default=dict)
    description: Mapped[Optional[str]] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    product_id: Mapped[Optional[int]] = mapped_column(ForeignKey("products.id", ondelete="CASCADE"))

    # 🔗 Relationships
    tenant = relationship("Tenant", back_populates="dpp_templates", lazy="selectin")
    product = relationship("Product", back_populates="dpp_templates", lazy="selectin")
