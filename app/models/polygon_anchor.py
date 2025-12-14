from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, ForeignKey, DateTime, text
from datetime import datetime
from app.core.db import Base


class PolygonAnchor(Base):
    __tablename__ = "polygon_anchors"  # ✅ dùng số nhiều để thống nhất với DB

    tenant = relationship("Tenant", back_populates="polygon_anchors", lazy="selectin")

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))
    tx_hash: Mapped[str | None] = mapped_column(String(255))
    network: Mapped[str | None] = mapped_column(String(64))
    block_number: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, server_default=text("NOW()"))

    # ✅ Quan hệ ngược: một Anchor có nhiều Subscription
    subscriptions = relationship("PolygonSubscription", back_populates="anchor", cascade="all, delete-orphan", lazy="selectin")
