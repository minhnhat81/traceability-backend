import json
import os
import asyncio
import httpx
import logging
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.security import verify_jwt  # ✅ import sớm

from app.core.db import get_async_session
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends


# ----------------------------------------------------------
# 🌍 FastAPI App Initialization (đặt TRƯỚC import routers)
# ----------------------------------------------------------
app = FastAPI(title="Traceability Portal Backend")

# ===== CORS CONFIG (không dùng "*" khi allow_credentials=True) =====
ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:3001",
    "http://localhost:3002",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:3002",
    "https://traceability-frontend-ayuz9avhr-nhats-projects-b54740d6.vercel.app",
]
# Cho phép bất kỳ port localhost (dành cho môi trường dev)
ALLOW_ORIGIN_REGEX = r"https://.*\.vercel\.app$"

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,           # danh sách cố định
    allow_origin_regex=ALLOW_ORIGIN_REGEX,   # cho phép các port localhost động
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],                    # để debug header CORS
)

logger = logging.getLogger("uvicorn")
logger.setLevel(logging.INFO)

# ----------------------------------------------------------
# 🔗 Routers Import & Registration
# ----------------------------------------------------------
from app.routers import (
    ws,
    configs_blockchain,
    rbac_io,
    polygon,
    anchor,
    audit,
    customs,
    customers,
    map as map_router,
    emissions,
    vc_verify,
    dpp_templates,
    suppliers,
    market,
    ledger,
    dashboard,
    consumer,
    compliance,
    products,
    batches,
    epcis,
    documents,
    vc,
    observer,
    configs,
    tenants,
    users,
    roles,
    scopes,
    bindings,
    export_pack,
    auth,
    evidence,
    blockchain,
    suppliers,  # giữ nguyên như code gốc dù bị lặp
    farm,
    material,
    batch_links,
    dpp_public,
)

app.include_router(products.router)
app.include_router(batches.router)
app.include_router(epcis.router)
app.include_router(documents.router)
app.include_router(vc.router)
app.include_router(observer.router)
app.include_router(configs.router)
app.include_router(audit.router)
app.include_router(tenants.router)
app.include_router(users.router)
app.include_router(auth.router)
app.include_router(roles.router)
app.include_router(scopes.router)
app.include_router(bindings.router)
app.include_router(dpp_templates.router)
app.include_router(export_pack.router)
app.include_router(suppliers.router)
app.include_router(market.router)
app.include_router(ledger.router)
app.include_router(dashboard.router)
app.include_router(consumer.router)
app.include_router(compliance.router)
app.include_router(vc_verify.router)
app.include_router(emissions.router)
app.include_router(map_router.router)
app.include_router(customers.router)
app.include_router(customs.router)
app.include_router(polygon.router)
app.include_router(rbac_io.router)
app.include_router(configs_blockchain.router)
app.include_router(ws.router)
app.include_router(evidence.router)
app.include_router(anchor.router)
app.include_router(blockchain.router)
app.include_router(farm.router)
app.include_router(material.router)
app.include_router(batch_links.router)
app.include_router(dpp_public.router)

# ----------------------------------------------------------
# ✅ Health Check
# ----------------------------------------------------------
@app.get("/health")
def health():
    return {"ok": True}


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


# ----------------------------------------------------------
# 🧾 Middleware: Audit logging (đã FIX việc đọc body)
# ----------------------------------------------------------
@app.middleware("http")
async def audit_mw(request: Request, call_next):
    origin = request.headers.get("origin")
    logger.info(
        f"[CORS-DBG] -> {request.method} {request.url.path} | "
        f"Origin={origin} | Content-Type={request.headers.get('content-type')}"
    )

    payload = None

    if request.method in ("POST", "PUT", "PATCH"):
        content_type = request.headers.get("content-type", "")
        if content_type.startswith("application/json"):
            try:
                body_bytes = await request.body()
                payload = json.loads(body_bytes.decode()) if body_bytes else None
            except Exception:
                payload = None

    response: Response = await call_next(request)

    acao = response.headers.get("access-control-allow-origin")
    acac = response.headers.get("access-control-allow-credentials")
    logger.info(
        f"[CORS-DBG] <- {response.status_code} {request.url.path} | "
        f"ACAO={acao} ACAC={acac}"
    )

    response.headers["X-Debug-Origin"] = origin or ""
    response.headers["X-Debug-Handled-By"] = "audit_mw"

    # ✅ Async audit log (KHÔNG còn warning)
    try:
        async for db in get_async_session():
            await db.execute(
                text(
                    'INSERT INTO audit_logs(tenant_id,"user",method,path,status,ip,payload,created_at) '
                    'VALUES (1,:u,:m,:p,:s,:i,:pl,NOW())'
                ),
                {
                    "u": request.headers.get("x-user", "unknown"),
                    "m": request.method,
                    "p": request.url.path,
                    "s": response.status_code,
                    "i": request.client.host if request.client else None,
                    "pl": json.dumps(payload) if payload is not None else None,
                },
            )
            await db.commit()
    except Exception as e:
        logger.warning(f"Audit log failed: {e}")

    return response



# ----------------------------------------------------------
# 🧩 Auto-sync EPCIS Context from GS1 (Hybrid Online + Local)
# ----------------------------------------------------------
GS1_CONTEXT_URL = "https://ref.gs1.org/standards/epcis/epcis-context.jsonld"
LOCAL_CONTEXT_PATH = "app/static/epcis/context/epcis-context.jsonld"


async def refresh_gs1_context():
    os.makedirs(os.path.dirname(LOCAL_CONTEXT_PATH), exist_ok=True)
    try:
        logger.info("🌍 Fetching latest EPCIS context from GS1...")
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(GS1_CONTEXT_URL)
            r.raise_for_status()
            content = r.text
        with open(LOCAL_CONTEXT_PATH, "w", encoding="utf-8") as f:
            f.write(content)
        logger.info("✅ EPCIS context updated successfully from GS1.")
    except Exception as e:
        if os.path.exists(LOCAL_CONTEXT_PATH):
            logger.warning(
                f"⚠️ Using local EPCIS context cache (network unavailable): {e}"
            )
        else:
            logger.error(
                f"❌ Failed to load EPCIS context and no local cache found: {e}"
            )
            fallback = {
                "@context": {
                    "epcis": "https://ref.gs1.org/epcis/",
                    "example": "https://example.org/vocab/",
                }
            }
            with open(LOCAL_CONTEXT_PATH, "w", encoding="utf-8") as f:
                json.dump(fallback, f, indent=2)
            logger.info("🧩 Created minimal fallback EPCIS context file.")


# ----------------------------------------------------------
# 🚀 Startup Hook
# ----------------------------------------------------------
@app.on_event("startup")
async def startup_event():
    # Log CORS cấu hình để xác minh
    logger.info(
        f"[CORS] allow_origins={ALLOWED_ORIGINS} allow_origin_regex={ALLOW_ORIGIN_REGEX} "
        f"allow_credentials=True allow_methods=* allow_headers=*"
    )
    asyncio.create_task(refresh_gs1_context())
    logger.info("🚀 Startup event triggered: EPCIS context auto-sync started.")


# ----------------------------------------------------------
# 🔎 DEBUG endpoint: Echo lại header để soi trực tiếp
# ----------------------------------------------------------
@app.get("/_debug/cors")
async def cors_echo(request: Request):
    return {
        "origin": request.headers.get("origin"),
        "access_control_request_method": request.headers.get(
            "access-control-request-method"
        ),
        "access_control_request_headers": request.headers.get(
            "access-control-request-headers"
        ),
    }
