from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.db import Base


class BatchLineage(Base):
    __tablename__ = "batch_lineage"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    parent_batch_id: Mapped[int] = mapped_column(ForeignKey("batches.id"))
    child_batch_id: Mapped[int] = mapped_column(ForeignKey("batches.id"))
    event_id: Mapped[Optional[int]] = mapped_column(ForeignKey("epcis_events.id"))
    transformation_type: Mapped[Optional[str]] = mapped_column(String(128))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    parent_batch = relationship("Batch", foreign_keys=[parent_batch_id], lazy="selectin")
    child_batch = relationship("Batch", foreign_keys=[child_batch_id], back_populates="lineages", lazy="selectin")
