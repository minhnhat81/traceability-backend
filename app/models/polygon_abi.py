from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Integer, Text, DateTime, text
from sqlalchemy.dialects.postgresql import JSONB
from app.core.db import Base

class PolygonAbi(Base):
    __tablename__ = "polygon_abi"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str | None] = mapped_column(Text)
    abi: Mapped[dict | None] = mapped_column(JSONB)
    created_at: Mapped[str | None] = mapped_column(DateTime, server_default=text("NOW()"))
