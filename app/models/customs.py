from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, ForeignKey
from app.core.db import Base

class Customs(Base):
    __tablename__ = "customs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    customer_id: Mapped[int] = mapped_column(ForeignKey("customers.id"))
    document_number: Mapped[str] = mapped_column(String(128))
    country: Mapped[str] = mapped_column(String(128))
    customer = relationship("Customer", back_populates="customs_records", lazy="selectin")

    # If your Customer model defines back_populates('customs_records'), enable:
    # customer = relationship("Customer", back_populates="customs_records", lazy="selectin")