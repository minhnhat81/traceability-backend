from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, text
from datetime import datetime
from app.core.db import Base


class Tenant(Base):
    __tablename__ = "tenants"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(128))
    code: Mapped[str] = mapped_column(String(64), unique=True)
    email: Mapped[str | None] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(32))
    address: Mapped[str | None] = mapped_column(String)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, server_default=text("NOW()"))

    # ✅ Quan hệ ngược tới các model khác
    users = relationship("User", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    suppliers = relationship("Supplier", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    brands = relationship("Brand", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    customers = relationship("Customer", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    products = relationship("Product", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    batches = relationship("Batch", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    events = relationship("Event", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    fabric_events = relationship("FabricEvent", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    polygon_anchors = relationship("PolygonAnchor", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")  # ✅ dòng quan trọng

    blockchain_anchors = relationship("BlockchainAnchor", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    configs_blockchain = relationship("ConfigsBlockchain", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    audit_logs = relationship("AuditLog", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    blockchain_configs = relationship("ConfigsBlockchain", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    compliance_results = relationship("ComplianceResult", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    credentials = relationship("Credential", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    data_sharing_agreements = relationship("DataSharingAgreement", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    documents = relationship("Document", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    domain = relationship("Domain", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    dpp_passports = relationship("DppPassport", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    epcis_events = relationship("EpcisEvent", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    portals = relationship("Portal", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    rbac_role_bindings = relationship("RbacRoleBinding", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    rbac_roles = relationship("RbacRole", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    rbac_scopes = relationship("RbacScope", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    farms = relationship("Farm", back_populates="tenant", cascade="all, delete-orphan", lazy="selectin")
    dpp_templates  = relationship("DppTemplate", back_populates="tenant", lazy="selectin")
    
