from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text, select
from app.core.db import get_db
from app.security import verify_jwt
from app.models.document import Document
from datetime import datetime
import hashlib
import json
import os
import uuid
import random
import string

router = APIRouter(prefix="/api/documents", tags=["documents"])

UPLOAD_DIR = "app/static/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


# ============================================================
# 🧩 Helper: Sinh mã doc_bundle_id tự động (một mã cho cả batch upload)
# ============================================================
def generate_doc_bundle_id() -> str:
    date_code = datetime.utcnow().strftime("%Y%m%d")
    rand_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"BATCH{date_code}-01-{rand_code}"


# ============================================================
# 📤 POST /api/documents/upload
# ============================================================
@router.post("/upload")
async def upload_documents(
    files: list[UploadFile] = File(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt)
):
    """
    📂 Upload một hoặc nhiều file chứng từ (Invoice, CO, GRS, GOTS, ...)
    - Tính SHA-256 hash, lưu metadata + tenant_id
    - Sinh VC payload + tự tạo doc_bundle_id cho mỗi batch upload
    - Nếu file đã tồn tại (trùng hash trong cùng tenant) → trả trạng thái "duplicate" + bundle/doc info
    """
    try:
        if not user or user.get("is_active") is False:
            raise HTTPException(status_code=403, detail="Inactive or unauthorized user")

        tenant_id = user.get("tenant_id")
        if not tenant_id:
            raise HTTPException(status_code=403, detail="Missing tenant_id")

        # 🔹 Mỗi batch upload -> tạo 1 bundle_id chung
        batch_bundle_id = generate_doc_bundle_id()

        results = []
        for file in files:
            try:
                content = await file.read()
                sha256_hash = hashlib.sha256(content).hexdigest()
                file_uuid = str(uuid.uuid4())
                stored_name = f"{file_uuid}_{file.filename}"
                save_path = os.path.join(UPLOAD_DIR, stored_name)

                # ✅ Kiểm tra trùng theo (tenant_id, file_hash)
                existing_q = await db.execute(
                    select(Document).where(
                        Document.tenant_id == tenant_id,
                        Document.file_hash == sha256_hash
                    )
                )
                existing_doc = existing_q.scalar_one_or_none()

                if existing_doc:
                    # Trả về thông tin hiện có (không ghi đè)
                    results.append({
                        "filename": file.filename,
                        "sha256": sha256_hash,
                        "path": existing_doc.path,
                        "status": "duplicate",
                        "doc_bundle_id": getattr(existing_doc, "doc_bundle_id", None),
                        "vc_hash_hex": getattr(existing_doc, "vc_hash_hex", None),
                    })
                    continue

                # Lưu file vật lý
                with open(save_path, "wb") as f:
                    f.write(content)

                # Metadata cơ bản (có thể mở rộng nếu cần)
                file_meta = {
                    "file_type": file.content_type,
                    "file_size": len(content),
                    "original_name": file.filename,
                }

                # Sinh VC payload (dùng làm “digital evidence” cho riêng file)
                vc_payload = {
                    "@context": ["https://www.w3.org/2018/credentials/v1"],
                    "type": ["VerifiableCredential", "DocumentCredential"],
                    "issuer": f"did:example:{tenant_id}",
                    "issuanceDate": datetime.utcnow().isoformat() + "Z",
                    "credentialSubject": {
                        "fileName": file.filename,
                        "fileType": file.content_type,
                        "fileHash": sha256_hash,
                        "storage": save_path,
                        "meta": file_meta,
                    },
                }
                vc_hash_hex = hashlib.sha256(
                    json.dumps(vc_payload, sort_keys=True).encode("utf-8")
                ).hexdigest()

                # Ghi DB
                new_doc = Document(
                    tenant_id=tenant_id,
                    file_name=file.filename,
                    file_type=file.content_type,
                    file_size=len(content),
                    path=save_path,
                    file_hash=sha256_hash,
                    vc_payload=vc_payload,
                    vc_hash_hex=vc_hash_hex,
                    doc_bundle_id=batch_bundle_id,
                    issued_at=datetime.utcnow(),
                    created_at=datetime.utcnow(),
                )
                db.add(new_doc)
                await db.commit()
                await db.refresh(new_doc)

                results.append({
                    "filename": file.filename,
                    "sha256": sha256_hash,
                    "path": save_path,
                    "status": "uploaded",
                    "doc_bundle_id": batch_bundle_id,
                    "vc_hash_hex": vc_hash_hex,
                    "vc": vc_payload,
                })

            except Exception as inner_e:
                await db.rollback()
                results.append({
                    "filename": file.filename,
                    "error": str(inner_e),
                    "status": "failed"
                })

        return {"ok": True, "results": results}

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Document upload failed: {e}")


# ============================================================
# 📋 GET /api/documents
# ============================================================
@router.get("")
async def list_documents(
    page: int = Query(1, ge=1),
    size: int = Query(10, le=200),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt)
):
    """
    📄 Liệt kê danh sách tài liệu của tenant
    """
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=403, detail="Missing tenant_id")

    offset = (page - 1) * size
    query = text(
        """
        SELECT id, file_name, file_hash, file_type, file_size, path,
               created_at, doc_bundle_id, vc_hash_hex
        FROM documents
        WHERE tenant_id = :tid
        ORDER BY created_at DESC
        LIMIT :lim OFFSET :off
        """
    )

    result = await db.execute(query, {"tid": tenant_id, "lim": size, "off": offset})
    rows = result.fetchall()

    total = await db.execute(
        text("SELECT COUNT(1) FROM documents WHERE tenant_id=:tid"), {"tid": tenant_id}
    )
    total_count = total.scalar() or 0

    return {
        "items": [
            {
                "file_hash": r.file_hash,
                "file_name": r.file_name,
                "file_type": r.file_type,
                "file_size": r.file_size,
                "created_at": str(r.created_at),
                "path": r.path,
                "doc_bundle_id": r.doc_bundle_id,
                "vc_hash_hex": r.vc_hash_hex,
            }
            for r in rows
        ],
        "meta": {"page": page, "size": size, "total": total_count},
    }


# ============================================================
# 📄 GET /api/documents/{sha256}
# ============================================================
@router.get("/{sha256}")
async def get_document(
    sha256: str,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt)
):
    """
    🔍 Lấy chi tiết file theo hash (giới hạn theo tenant)
    """
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=403, detail="Missing tenant_id")

    result = await db.execute(
        select(Document).where(
            Document.tenant_id == tenant_id,
            Document.file_hash == sha256
        )
    )
    doc = result.scalar_one_or_none()

    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    return {
        "sha256": doc.file_hash,
        "filename": doc.file_name,
        "file_type": doc.file_type,
        "file_size": doc.file_size,
        "created_at": str(doc.created_at),
        "path": doc.path,
        "doc_bundle_id": doc.doc_bundle_id,
        "vc_hash_hex": doc.vc_hash_hex,
        "vc_payload": doc.vc_payload,
    }
