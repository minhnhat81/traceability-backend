from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, ForeignKey
from app.core.db import Base

class ConfigsBlockchain(Base):
    __tablename__ = "configs_blockchain"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int] = mapped_column(ForeignKey("tenants.id"))
    chain_name: Mapped[str] = mapped_column(String(64))
    rpc_url: Mapped[str] = mapped_column(String(255))
    contract_address: Mapped[str] = mapped_column(String(255))

    tenant = relationship("Tenant", back_populates="blockchain_configs", lazy="selectin")
