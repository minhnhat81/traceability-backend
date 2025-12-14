from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from app.core.db import Base

class Event(Base):
    __tablename__ = "events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))
    batch_code: Mapped[str] = mapped_column(String(64), index=True)
    product_code: Mapped[str] = mapped_column(String(64), index=True)
    event_time: Mapped[str | None] = mapped_column(DateTime)
    biz_step: Mapped[str | None] = mapped_column(String(128))
    disposition: Mapped[str | None] = mapped_column(String(128))
    data: Mapped[dict | None] = mapped_column(JSONB)

    tenant = relationship("Tenant", back_populates="events", lazy="selectin")
