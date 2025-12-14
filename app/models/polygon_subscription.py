from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, ForeignKey, DateTime, text
from datetime import datetime
from app.core.db import Base


class PolygonSubscription(Base):
    __tablename__ = "polygon_subscriptions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    anchor_id: Mapped[int | None] = mapped_column(ForeignKey("polygon_anchors.id", ondelete="CASCADE"))
    event_name: Mapped[str | None] = mapped_column(String(128))
    callback_url: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime | None] = mapped_column(DateTime, server_default=text("NOW()"))

    # ✅ Quan hệ tới PolygonAnchor
    anchor = relationship("PolygonAnchor", back_populates="subscriptions", lazy="selectin")
