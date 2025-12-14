from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from nacl.signing import VerifyKey
from nacl.exceptions import BadSignatureError
import base64, json
from sqlalchemy.ext.asyncio import AsyncSession

# Import DB + DAO
from app.core.db import get_db
from app.services import dao_credentials  # bạn thêm file dao_credentials.py
from app.security import verify_jwt  # nếu bạn có JWT guard

router = APIRouter(prefix="/api/vc", tags=["vc-verify"])

# ---- Pydantic model for Swagger ----
class VerifyVCRequest(BaseModel):
    jws: str
    public_key_base64: str

@router.post("/verify")
async def verify_vc(
    req: VerifyVCRequest,
    db: AsyncSession = Depends(get_db),
    user=Depends(verify_jwt),  # bỏ nếu bạn chưa dùng JWT
):
    """
    ✅ Verify detached JWS using provided Ed25519 public key.
    ✅ Save verification result to 'credentials' table.
    """
    try:
        # --- Parse JWS ---
        header_b64, payload_b64, signature_b64 = req.jws.split(".")
        message = f"{header_b64}.{payload_b64}".encode()
        signature = base64.urlsafe_b64decode(signature_b64 + "==")
        public_key_bytes = base64.b64decode(req.public_key_base64)

        verify_key = VerifyKey(public_key_bytes)
        verify_key.verify(message, signature)

        payload = json.loads(base64.urlsafe_b64decode(payload_b64 + "==").decode())

        # ✅ Lưu kết quả vào bảng credentials
        tenant_id = user.get("tenant_id") if user else 1  # fallback tạm
        hash_hex = payload.get("hash")
        vc_type = payload.get("type")
        status = "verified"

        await dao_credentials.upsert_credential(
            db=db,
            tenant_id=tenant_id,
            hash_hex=hash_hex,
            status=status,
            vc_payload=payload,
        )

        return {
            "ok": True,
            "verified": True,
            "payload": payload,
            "tenant_id": tenant_id,
            "saved": True
        }

    except BadSignatureError:
        raise HTTPException(status_code=400, detail="❌ Invalid signature")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {e}")
