from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt
import base64, json, time, uuid
from nacl.signing import SigningKey

router = APIRouter(prefix="/api/vc", tags=["vc"])

def _b64url(d: bytes) -> str:
    return base64.urlsafe_b64encode(d).decode().rstrip("=")

# ============================================================
# 📜 POST /api/vc/issue
# ============================================================
@router.post("/issue")
async def issue_vc(body: dict, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    ✳️ Issue Verifiable Credential (VC) cho document hash (ký thật bằng Ed25519)
    """
    subject = body.get("subject") or user.get("did") or f"did:example:{user.get('tenant_id')}"
    vctype = body.get("type") or "DocumentCredential"
    hash_hex = body.get("hash_hex")

    if not hash_hex:
        raise HTTPException(status_code=400, detail="hash_hex is required")

    # 🔑 Sinh cặp khóa Ed25519
    signing_key = SigningKey.generate()
    verify_key = signing_key.verify_key
    private_key_b64 = base64.b64encode(signing_key.encode()).decode()
    public_key_b64 = base64.b64encode(verify_key.encode()).decode()

    # 🔏 Tạo payload + JWS
    header = {"alg": "EdDSA", "typ": "JWT"}
    payload = {
        "sub": subject,
        "type": vctype,
        "hash": hash_hex,
        "iat": int(time.time()),
    }

    signing_input = f"{_b64url(json.dumps(header).encode())}.{_b64url(json.dumps(payload).encode())}"
    signature = signing_key.sign(signing_input.encode()).signature
    jws = f"{signing_input}.{_b64url(signature)}"

    try:
        await db.execute(text("""
            INSERT INTO credentials(id, tenant_id, subject, type, hash_hex, jws, public_key_base64, created_at)
            VALUES (:id, :tid, :sub, :typ, :h, :jws, :pk, NOW())
        """), {
            "id": str(uuid.uuid4()),
            "tid": user.get("tenant_id"),
            "sub": subject,
            "typ": vctype,
            "h": hash_hex,
            "jws": jws,
            "pk": public_key_b64
        })
        await db.commit()

        return {
            "ok": True,
            "jws": jws,
            "hash_hex": hash_hex,
            "public_key_base64": public_key_b64
        }

    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Issue VC failed: {e}")

# ============================================================
# 📋 GET /api/vc/list
# ============================================================
@router.get("/list")
async def list_vc(page: int = 1, size: int = 10, db: AsyncSession = Depends(get_db), user=Depends(verify_jwt)):
    """
    📄 Danh sách VC theo tenant
    """
    tenant_id = user.get("tenant_id")
    if not tenant_id:
        raise HTTPException(status_code=403, detail="Missing tenant_id")

    page = max(1, page)
    size = max(1, min(200, size))
    offset = (page - 1) * size

    result = await db.execute(text("""
        SELECT id, subject, type, hash_hex, jws, public_key_base64, created_at
        FROM credentials
        WHERE tenant_id = :tid
        ORDER BY created_at DESC
        LIMIT :lim OFFSET :off
    """), {"tid": tenant_id, "lim": size, "off": offset})
    rows = result.fetchall()

    total = await db.execute(text("SELECT COUNT(1) FROM credentials WHERE tenant_id=:tid"), {"tid": tenant_id})
    total_count = total.scalar() or 0

    return {
        "data": [
            {
                "id": r.id,
                "subject": r.subject,
                "type": r.type,
                "hash_hex": r.hash_hex,
                "jws": r.jws,
                "public_key_base64": r.public_key_base64,
                "created_at": str(r.created_at)
            } for r in rows
        ],
        "meta": {"total": total_count, "page": page, "size": size}
    }
