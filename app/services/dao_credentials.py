import json
from sqlalchemy import text

async def upsert_credential(db, tenant_id: int, hash_hex: str, status: str, vc_payload: dict):
    check_sql = "SELECT id FROM credentials WHERE tenant_id=:t AND hash_hex=:h"
    row = await db.execute(text(check_sql), {"t": tenant_id, "h": hash_hex})
    exists = row.first()

    verified_flag = (status == 'verified')

    if exists:
        sql = """
        UPDATE credentials
        SET status=:s, vc_payload=:p, verified=:v
        WHERE tenant_id=:t AND hash_hex=:h
        """
    else:
        sql = """
        INSERT INTO credentials (tenant_id, hash_hex, status, vc_payload, verified, created_at)
        VALUES (:t, :h, :s, :p, :v, NOW())
        """

    await db.execute(
        text(sql),
        {"t": tenant_id, "h": hash_hex, "s": status, "p": json.dumps(vc_payload), "v": verified_flag}
    )
    await db.commit()
