from .ws import hub

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.db import get_db
from app.security import verify_jwt, check_permission

router = APIRouter(prefix="/api/observer", tags=["observer"])

@router.get("/fabric")
def fabric_events(db: Session = Depends(get_db), user=Depends(verify_jwt)):
    rows = db.execute(text("SELECT id, tx_id, block_number, event_name FROM fabric_events ORDER BY id DESC LIMIT 200")).fetchall()
    return {"items":[{"id":r[0],"tx_id":r[1],"block":r[2],"name":r[3]} for r in rows]}


from fastapi import Body
from sqlalchemy import text as _text

@router.post("/ingest/fabric")
def ingest_fabric(payload: dict = Body(...), db: Session = Depends(get_db)):
    db.execute(_text("INSERT INTO fabric_events(tx_id,block_number,chaincode_id,event_name,payload) VALUES (:tx,:bn,:cc,:en,:pl)"),
               {"tx": payload.get("tx_id"), "bn": payload.get("block_number"), "cc": payload.get("chaincode_id"), "en": payload.get("event_name"), "pl": payload})
    db.commit(); return {"ok": True}


from sqlalchemy.orm import Session
from sqlalchemy import text as _text
from fastapi import Depends
from app.core.db import get_db


@router.post("/ingest/fabric/anchored")
def anchored_upsert(payload: dict, db: Session = Depends(get_db)):
    ref = (payload or {}).get("ref")
    tx = (payload or {}).get("tx_id")
    h  = (payload or {}).get("hash")
    if not ref or not h:
        return {"ok": False, "error":"missing ref/hash"}
    db.execute(_text("INSERT INTO anchors(tenant_id, ref, hash, network, tx_hash, meta) VALUES (1,:r,:h,'fabric',:tx,:m)"),
               {"r": ref, "h": h, "tx": tx, "m": payload})
    db.execute(_text("INSERT INTO dpp_passports(tenant_id, product_code, batch_code, payload, version) VALUES (1, :p, :b, :pl, '1.0')"),
               {"p": ref if ref and ref.isupper() else None, "b": ref if ref and ref.startswith('LOT-') else None, "pl": {"anchor_hash": h, "ref": ref}})
    db.commit()
    import asyncio; asyncio.create_task(hub.broadcast({"source":"fabric","type":"anchor","payload":payload}))
    return {"ok": True}


from sqlalchemy.orm import Session
from sqlalchemy import text as _text
from fastapi import Depends
from app.core.db import get_db

@router.post("/ingest/polygon/anchored")
def anchored_polygon(payload: dict, db: Session = Depends(get_db)):
    ref = (payload or {}).get("ref")
    tx = (payload or {}).get("tx_hash") or (payload or {}).get("transactionHash")
    h  = (payload or {}).get("hash") or (payload or {}).get("anchorHash")
    if not ref or not h:
        return {"ok": False, "error":"missing ref/hash"}
    db.execute(_text("INSERT INTO anchors(tenant_id, ref, hash, network, tx_hash, meta) VALUES (1,:r,:h,'polygon',:tx,:m)"),
               {"r": ref, "h": h, "tx": tx, "m": payload})
    db.commit()
    import asyncio; asyncio.create_task(hub.broadcast({"source":"fabric","type":"anchor","payload":payload}))
    return {"ok": True}
