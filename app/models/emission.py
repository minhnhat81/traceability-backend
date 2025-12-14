from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, Float, ForeignKey, DateTime, text
from datetime import datetime
from app.core.db import Base

class Emission(Base):
    __tablename__ = "emissions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    batch_id: Mapped[int] = mapped_column(ForeignKey("batches.id"))
    co2_kg: Mapped[float] = mapped_column(Float)
    recorded_at: Mapped[datetime] = mapped_column(DateTime, server_default=text("NOW()"))

    # Only define reverse if your Batch model defines relationship("Emission", back_populates="batch", lazy="selectin")
    batch = relationship("Batch", back_populates="emissions", lazy="selectin")
