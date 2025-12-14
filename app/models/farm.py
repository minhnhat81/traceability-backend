from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Integer, String, Numeric, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.db import Base


class Farm(Base):
    __tablename__ = "farms"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tenants.id"))
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    code: Mapped[Optional[str]] = mapped_column(String(64), unique=True)
    gln: Mapped[Optional[str]] = mapped_column(String(64))
    farm_type: Mapped[Optional[str]] = mapped_column(String(64))
    location: Mapped[Optional[dict]] = mapped_column(JSONB)
    size_ha: Mapped[Optional[float]] = mapped_column(Numeric)
    certification: Mapped[Optional[dict]] = mapped_column(JSONB)
    contact_info: Mapped[Optional[dict]] = mapped_column(JSONB)
    extra_data: Mapped[Optional[dict]] = mapped_column(JSONB, default={})
    status: Mapped[str] = mapped_column(String(32), default="active", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )

    # 🔗 Relationships
    tenant  = relationship("Tenant", back_populates="farms", lazy="selectin")
    batches = relationship("Batch", back_populates="origin_farm", lazy="selectin")

