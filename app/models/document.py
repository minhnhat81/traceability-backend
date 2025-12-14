from __future__ import annotations
from typing import Optional, Dict, Any
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.db import Base


class Document(Base):
    """
    📄 Document metadata + hash + Verifiable Credential payload
    Dùng cho: Invoice, CO, GRS, GOTS, Test Report, ...
    """
    __tablename__ = "documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))

    # 🧩 Thông tin file cơ bản
    file_name: Mapped[Optional[str]] = mapped_column(String(255))
    file_type: Mapped[Optional[str]] = mapped_column(String(64))
    file_size: Mapped[Optional[int]] = mapped_column(Integer)
    path: Mapped[Optional[str]] = mapped_column(String(512))  # đường dẫn local hoặc S3

    # 🔐 Hash và VC payload
    file_hash: Mapped[Optional[str]] = mapped_column(String(128), index=True, unique=True)
    vc_payload: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    vc_hash_hex: Mapped[str] = mapped_column(Text, nullable=True)     # ✅ Thêm mới
    doc_bundle_id: Mapped[str] = mapped_column(String(64), nullable=True)  # ✅ Thêm mới

    # 🕒 Thời gian phát hành và tạo
    issued_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    # 🔗 Liên kết tenant
    tenant = relationship("Tenant", back_populates="documents", lazy="selectin")
