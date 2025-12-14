
from fastapi import APIRouter, Depends
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
import tempfile, os, datetime, json

router = APIRouter(prefix="/api/export", tags=["export"])

@router.get("/pack.pdf")
def export_pack(batch_code: str, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    # Query basic info
    b = db.execute(text("SELECT code, product_code, mfg_date, country FROM batches WHERE code=:c"), {"c": batch_code}).fetchone()
    evs = db.execute(text("SELECT event_time, event_type, action, biz_step, disposition FROM epcis_events WHERE batch_code=:c ORDER BY event_time"), {"c": batch_code}).fetchall()
    docs = db.execute(text("SELECT title, hash FROM documents ORDER BY id DESC LIMIT 50")).fetchall()

    fd, path = tempfile.mkstemp(suffix=".pdf"); os.close(fd)
    c = canvas.Canvas(path, pagesize=A4); w, h = A4
    y = h - 40
    c.setFont("Helvetica-Bold", 14); c.drawString(40, y, f"Export Compliance Pack - Batch {batch_code}"); y -= 24
    c.setFont("Helvetica", 10)
    c.drawString(40, y, f"Generated: {datetime.datetime.utcnow().isoformat()}Z"); y -= 18
    if b:
        c.drawString(40, y, f"Product: {b[1]}   MfgDate: {b[2]}   Country: {b[3]}"); y -= 18
    y -= 8
    c.setFont("Helvetica-Bold", 12); c.drawString(40, y, "EPCIS Events"); y -= 16
    c.setFont("Helvetica", 10)
    for r in evs[:40]:
        line = f"{r[0]}  {r[1]}  {r[2]}  {r[3]}  {r[4]}"
        c.drawString(50, y, line[:110]); y -= 14
        if y < 60: c.showPage(); y = h - 40
    y -= 8
    c.setFont("Helvetica-Bold", 12); c.drawString(40, y, "Documents"); y -= 16
    c.setFont("Helvetica", 10)
    for d in docs[:40]:
        c.drawString(50, y, f"{d[0]}   sha256={d[1][:16]}..."); y -= 14
        if y < 60: c.showPage(); y = h - 40
    c.showPage(); c.save()
    return FileResponse(path, media_type="application/pdf", filename=f"export_pack_{batch_code}.pdf")
