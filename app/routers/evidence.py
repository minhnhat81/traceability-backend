# app/routers/evidence.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt
from nacl.signing import VerifyKey
from nacl.exceptions import BadSignatureError
import base64
import json

router = APIRouter(prefix="/api/evidence", tags=["digital-evidence"])


# ==========================================================
# 📋 GET /api/evidence/list
# ==========================================================
@router.get("/list")
async def list_evidences(
    page: int = Query(1, ge=1),
    size: int = Query(10, le=200),
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt)
):
    """
    📄 Liệt kê toàn bộ chứng từ + VC + trạng thái xác minh (real-time)
    """
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=403, detail="Missing tenant_id")

    offset = (page - 1) * size

    query = text("""
        SELECT d.id AS document_id,
               d.file_name,
               d.file_type,
               d.file_size,
               d.path,
               d.hash AS file_hash,
               d.created_at AS document_created,
               c.id AS vc_id,
               c.subject,
               c.type AS vc_type,
               c.hash_hex,
               c.jws,
               c.public_key_base64,
               c.created_at AS vc_created
        FROM documents d
        LEFT JOIN credentials c ON d.hash = c.hash_hex
        WHERE d.tenant_id = :tid
        ORDER BY d.created_at DESC
        LIMIT :lim OFFSET :off
    """)

    result = await db.execute(query, {"tid": tenant_id, "lim": size, "off": offset})
    rows = result.fetchall()

    # ==========================================================
    # 2️⃣ Real-time verify VC cho từng document (nếu có)
    # ==========================================================
    evidences = []
    for r in rows:
        verify_result = {"verified": False, "error": None}

        if r.jws and r.public_key_base64:
            try:
                header_b64, payload_b64, signature_b64 = r.jws.split(".")
                message = f"{header_b64}.{payload_b64}".encode()
                signature = base64.urlsafe_b64decode(signature_b64 + "==")
                public_key_bytes = base64.b64decode(r.public_key_base64)

                verify_key = VerifyKey(public_key_bytes)
                verify_key.verify(message, signature)

                payload = json.loads(base64.urlsafe_b64decode(payload_b64 + "==").decode())
                verify_result.update({
                    "verified": True,
                    "payload": payload
                })
            except BadSignatureError:
                verify_result["error"] = "Invalid signature"
            except Exception as e:
                verify_result["error"] = str(e)

        evidences.append({
            "document": {
                "id": r.document_id,
                "filename": r.file_name,
                "file_type": r.file_type,
                "file_size": r.file_size,
                "hash": r.file_hash,
                "path": r.path,
                "created_at": str(r.document_created)
            },
            "verifiable_credential": {
                "id": r.vc_id,
                "subject": r.subject,
                "type": r.vc_type,
                "hash_hex": r.hash_hex,
                "public_key_base64": r.public_key_base64,
                "jws": r.jws,
                "created_at": str(r.vc_created) if r.vc_created else None
            } if r.vc_id else None,
            "verify_status": verify_result
        })

    total = await db.execute(
        text("SELECT COUNT(1) FROM documents WHERE tenant_id=:tid"),
        {"tid": tenant_id}
    )
    total_count = total.scalar() or 0

    # ==========================================================
    # 3️⃣ Trả về kết quả tổng hợp
    # ==========================================================
    return {
        "ok": True,
        "items": evidences,
        "meta": {"page": page, "size": size, "total": total_count}
    }
