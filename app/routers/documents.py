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
# 🧩 Helper: Sinh mã doc_bundle_id
# ============================================================
def generate_doc_bundle_id() -> str:
    date_code = datetime.utcnow().strftime("%Y%m%d")
    rand_code = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"BATCH{date_code}-01-{rand_code}"


# ============================================================
# 📤 POST /api/documents/upload
# ============================================================
@router.post("/upload")
async def upload_documents(
    files: list[UploadFile] = File(...),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    try:
        if not user or user.get("is_active") is False:
            raise HTTPException(403, "Inactive or unauthorized user")

        tenant_id = user.get("tenant_id")
        if not tenant_id:
            raise HTTPException(403, "Missing tenant_id")

        batch_bundle_id = generate_doc_bundle_id()
        results = []

        for file in files:
            try:
                content = await file.read()
                sha256_hash = hashlib.sha256(content).hexdigest()

                existing_q = await db.execute(
                    select(Document).where(
                        Document.tenant_id == tenant_id,
                        Document.file_hash == sha256_hash,
                    )
                )
                existing_doc = existing_q.scalar_one_or_none()

                if existing_doc:
                    results.append({
                        "filename": file.filename,
                        "sha256": sha256_hash,
                        "status": "duplicate",
                        "doc_bundle_id": existing_doc.doc_bundle_id,
                        "vc_hash_hex": existing_doc.vc_hash_hex,
                    })
                    continue

                file_uuid = str(uuid.uuid4())
                stored_name = f"{file_uuid}_{file.filename}"
                save_path = os.path.join(UPLOAD_DIR, stored_name)

                with open(save_path, "wb") as f:
                    f.write(content)

                vc_payload = {
                    "@context": ["https://www.w3.org/2018/credentials/v1"],
                    "type": ["VerifiableCredential", "DocumentCredential"],
                    "issuer": f"did:example:{tenant_id}",
                    "issuanceDate": datetime.utcnow().isoformat() + "Z",
                    "credentialSubject": {
                        "fileName": file.filename,
                        "fileHash": sha256_hash,
                        "storage": save_path,
                    },
                }

                vc_hash_hex = hashlib.sha256(
                    json.dumps(vc_payload, sort_keys=True).encode("utf-8")
                ).hexdigest()

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
                    "status": "uploaded",
                    "doc_bundle_id": batch_bundle_id,
                    "vc_hash_hex": vc_hash_hex,
                })

            except Exception as inner_e:
                await db.rollback()
                results.append({
                    "filename": file.filename,
                    "status": "failed",
                    "error": str(inner_e),
                })

        return {"ok": True, "results": results}

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"Document upload failed: {e}")


# ============================================================
# 📋 GET /api/documents
# ============================================================
@router.get("")
async def list_documents(
    page: int = Query(1, ge=1),
    size: int = Query(10, le=200),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(403, "Missing tenant_id")

    offset = (page - 1) * size

    result = await db.execute(
        text("""
            SELECT file_name, file_hash, file_type, file_size,
                   created_at, path, doc_bundle_id, vc_hash_hex
            FROM documents
            WHERE tenant_id=:t
            ORDER BY created_at DESC
            LIMIT :l OFFSET :o
        """),
        {"t": tenant_id, "l": size, "o": offset},
    )

    rows = result.fetchall()
    total = await db.execute(
        text("SELECT COUNT(1) FROM documents WHERE tenant_id=:t"),
        {"t": tenant_id},
    )

    return {
        "items": [
            {
                "file_name": r.file_name,
                "file_hash": r.file_hash,
                "file_type": r.file_type,
                "file_size": r.file_size,
                "created_at": str(r.created_at),
                "path": r.path,
                "doc_bundle_id": r.doc_bundle_id,
                "vc_hash_hex": r.vc_hash_hex,
            }
            for r in rows
        ],
        "meta": {"page": page, "size": size, "total": total.scalar()},
    }


# ============================================================
# 📄 DELETE /api/documents/{file_hash}
# ============================================================
@router.delete("/{file_hash}")
async def delete_document(
    file_hash: str,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),
):
    tenant_id = int(user.get("tenant_id") or 0)

    q = await db.execute(
        text("""
            SELECT id, vc_hash_hex
            FROM documents
            WHERE tenant_id=:t AND file_hash=:h
        """),
        {"t": tenant_id, "h": file_hash},
    )
    doc = q.mappings().first()

    if not doc:
        raise HTTPException(404, "Document not found")

    # ❗ CHỈ CẤM XOÁ KHI ĐÃ KÝ VC (EPCIS / pháp lý)
    if doc["vc_hash_hex"]:
        raise HTTPException(
            400,
            "Document already signed / used in EPCIS, cannot delete",
        )

    await db.execute(
        text("DELETE FROM documents WHERE tenant_id=:t AND file_hash=:h"),
        {"t": tenant_id, "h": file_hash},
    )
    await db.commit()

    return {"ok": True, "deleted": file_hash}
