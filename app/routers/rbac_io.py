import io
import csv
import json
from fastapi import (
    APIRouter,
    Depends,
    UploadFile,
    File,
    HTTPException,
    Query,
    Response
)
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission

router = APIRouter(prefix="/api/rbac/io", tags=["rbac"])


# =====================================
# ✅ Export roles / scopes (async)
# =====================================
@router.get("/export")
async def export(
    kind: str = Query(..., pattern="^(roles|scopes)$"),
    fmt: str = Query("csv"),
    db=Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    🧾 Xuất dữ liệu roles hoặc scopes.
    - kind: roles | scopes
    - fmt: csv | json
    """
    has_permission = await check_permission(
        db,
        user,
        resource="configs",
        action="read",
        body={},
        path="/api/rbac/io/export",
        method="GET",
    )
    if not has_permission:
        raise HTTPException(403, "Permission denied")

    try:
        result = await db.execute(text(f"SELECT * FROM {kind} ORDER BY id"))
        rows = result.mappings().all()
    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"Database error: {e}")

    # Trả về JSON nếu chọn fmt=json
    if fmt.lower() == "json":
        return rows

    # Mặc định: xuất CSV
    buf = io.StringIO()
    if rows:
        writer = csv.DictWriter(buf, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        for r in rows:
            writer.writerow(dict(r))

    return Response(content=buf.getvalue(), media_type="text/csv")


# =====================================
# ✅ Import roles / scopes (async)
# =====================================
@router.post("/import")
async def import_items(
    kind: str = Query(..., pattern="^(roles|scopes)$"),
    fmt: str = Query("csv"),
    file: UploadFile = File(...),
    db=Depends(get_db),
    user=Depends(verify_jwt),
):
    """
    📥 Nhập dữ liệu roles hoặc scopes.
    - kind: roles | scopes
    - fmt: csv | json
    """
    has_permission = await check_permission(
        db,
        user,
        resource="configs",
        action="create",
        body={},
        path="/api/rbac/io/import",
        method="POST",
    )
    if not has_permission:
        raise HTTPException(403, "Permission denied")

    try:
        content = await file.read()
        items = []

        if fmt.lower() == "json":
            items = json.loads(content.decode())
        else:
            buf = io.StringIO(content.decode())
            reader = csv.DictReader(buf)
            items = list(reader)

        count = 0
        for it in items:
            if kind == "roles":
                await db.execute(
                    text(
                        "INSERT INTO roles(name, description, tenant_id) "
                        "VALUES (:n, :d, 1) "
                        "ON CONFLICT (name) DO NOTHING"
                    ),
                    {"n": it.get("name"), "d": it.get("description")},
                )
            else:
                await db.execute(
                    text(
                        "INSERT INTO scopes(name, product_code, batch_code, tenant_id) "
                        "VALUES (:n, :p, :b, 1) "
                        "ON CONFLICT (name) DO NOTHING"
                    ),
                    {
                        "n": it.get("name"),
                        "p": it.get("product_code"),
                        "b": it.get("batch_code"),
                    },
                )
            count += 1

        await db.commit()
        return {"ok": True, "count": count}

    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"Import error: {e}")
