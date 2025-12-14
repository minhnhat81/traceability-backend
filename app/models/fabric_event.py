from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, BigInteger, DateTime, text, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from app.core.db import Base

class FabricEvent(Base):
    __tablename__ = "fabric_events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))
    tx_id: Mapped[str | None] = mapped_column(String(128))
    block_number: Mapped[int | None] = mapped_column(BigInteger)
    chaincode_id: Mapped[str | None] = mapped_column(String(128))
    event_name: Mapped[str | None] = mapped_column(String(128))
    payload: Mapped[dict | None] = mapped_column(JSONB)
    status: Mapped[str | None] = mapped_column(String(32), server_default=text("'RECEIVED'"))
    ts: Mapped[str | None] = mapped_column(DateTime, server_default=text("NOW()"))

    tenant = relationship("Tenant", back_populates="fabric_events", lazy="selectin")
