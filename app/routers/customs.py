
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, scope_where_clause, check_permission
import io, zipfile, json, datetime

router = APIRouter(prefix="/api/customs", tags=["customs"])

@router.get("/search")
def search(batch_code: str | None = Query(None), product_code: str | None = Query(None), db: Session = Depends(get_db), user=Depends(verify_jwt)):
    where = scope_where_clause(db, user, 'batches')
    sql = "SELECT b.id, b.code, b.product_code, b.country, b.mfg_date FROM batches b WHERE " + where
    params = {}
    if batch_code:
        sql += " AND b.code = :bc"; params['bc']=batch_code
    if product_code:
        sql += " AND b.product_code = :pc"; params['pc']=product_code
    sql += " ORDER BY b.id DESC LIMIT 200"
    rows = db.execute(text(sql), params).fetchall()
    return {"items":[{"id":r[0], "batch_code":r[1], "product_code": r[2], "country": r[3], "mfg_date": str(r[4])} for r in rows]}

@router.get("/export")
def export_pack(batch_code: str, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    if not check_permission(db, user, 'batches', 'read', {"batch_code": batch_code}, path='/api/customs/export', method='GET'):
        return Response(content="denied", status_code=403)
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as z:
        man = {"batch_code": batch_code, "generated_at": datetime.datetime.utcnow().isoformat()}
        z.writestr("manifest.json", json.dumps(man, indent=2))
        dpp = db.execute(text("SELECT payload FROM dpp_passports WHERE batch_code=:b OR product_code=(SELECT product_code FROM batches WHERE code=:b) ORDER BY id DESC LIMIT 1"), {"b": batch_code}).scalar() or {}
        z.writestr("dpp.json", json.dumps(dpp, indent=2) if isinstance(dpp, dict) else str(dpp))
        anchors = db.execute(text("SELECT network, tx_hash, ref FROM anchors WHERE ref=:b"), {"b": batch_code}).fetchall()
        z.writestr("anchors.json", json.dumps([{"network":a[0],"tx_hash":a[1],"ref":a[2]} for a in anchors], indent=2))
    return Response(content=buf.getvalue(), media_type="application/zip", headers={"Content-Disposition": f"attachment; filename=export_{batch_code}.zip"})


@router.get("/export_pdf")
def export_pdf(batch_code: str, db: Session = Depends(get_db), user=Depends(verify_jwt)):
    if not check_permission(db, user, 'batches', 'read', {"batch_code": batch_code}, path='/api/customs/export_pdf', method='GET'):
        return Response(content="denied", status_code=403)
    import io, json
    buf = io.BytesIO()
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.pdfgen import canvas
        c = canvas.Canvas(buf, pagesize=A4)
        width, height = A4
        c.setFont("Helvetica-Bold", 14); c.drawString(40, height-40, f"Export Compliance Pack - {batch_code}")
        c.setFont("Helvetica", 10)
        # DPP + anchors summary
        from sqlalchemy import text as sqltext
        dpp = db.execute(sqltext("SELECT payload FROM dpp_passports WHERE batch_code=:b OR product_code=(SELECT product_code FROM batches WHERE code=:b) ORDER BY id DESC LIMIT 1"), {"b": batch_code}).scalar()
        anchors = db.execute(sqltext("SELECT network, tx_hash, ref, hash FROM anchors WHERE ref=:b OR ref=(SELECT product_code FROM batches WHERE code=:b) ORDER BY id DESC"), {"b": batch_code}).fetchall()
        y = height-70
        c.drawString(40,y, "DPP Snapshot:"); y-=14
        c.setFont("Helvetica", 9)
        dpp_s = json.dumps(dpp if isinstance(dpp, dict) else {"payload":str(dpp)}, ensure_ascii=False)[:900]
        for line in [dpp_s[i:i+95] for i in range(0,len(dpp_s),95)]:
            c.drawString(44,y,line); y-=12
            if y<60: c.showPage(); y=height-40
        c.setFont("Helvetica", 10); c.drawString(40,y, "Anchors:"); y-=14
        for a in anchors:
            line = f"- {a[0]} tx={a[1]} ref={a[2]} hash={a[3]}"
            c.setFont("Helvetica", 9); c.drawString(44,y,line); y-=12
            if y<60: c.showPage(); y=height-40
        c.showPage(); c.save()
        pdf = buf.getvalue()
    except Exception:
        # Fallback minimal PDF
        payload = f"Export Pack for {batch_code}\nSee JSON endpoints for details."
        pdf = (b"%PDF-1.4\n1 0 obj<<>>endobj\n"
               b"2 0 obj<</Length 44>>stream\nBT /F1 24 Tf 72 720 Td ("+payload.encode('latin-1','ignore')+b") Tj ET\nendstream endobj\n"
               b"3 0 obj<</Type /Page /Parent 4 0 R /MediaBox [0 0 595 842] /Contents 2 0 R>>endobj\n"
               b"4 0 obj<</Type /Pages /Kids [3 0 R] /Count 1>>endobj\n"
               b"5 0 obj<</Type /Catalog /Pages 4 0 R>>endobj\n"
               b"xref\n0 6\n0000000000 65535 f \n"
               b"trailer<</Root 5 0 R /Size 6>>\nstartxref\n0\n%%EOF")
    return Response(content=pdf, media_type="application/pdf", headers={"Content-Disposition": f"attachment; filename=export_{batch_code}.pdf"})
