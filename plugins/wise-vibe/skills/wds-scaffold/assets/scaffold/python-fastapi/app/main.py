"""{{PROJECT_NAME}} — FastAPI entrypoint."""
from fastapi import FastAPI
from fastapi.responses import JSONResponse

from app import db
from app.core.config import settings

app = FastAPI(title=settings.app_name)


@app.get("/health")
def health():
    try:
        db.ping()
        db_status = "ok"
    except Exception as exc:  # noqa: BLE001 — 헬스 응답에 원인 노출(시크릿 제외)
        db_status = f"error: {type(exc).__name__}"
    body = {"status": "ok" if db_status == "ok" else "degraded",
            "env": settings.app_env, "db": {"engine": settings.db_engine, "status": db_status}}
    return JSONResponse(body, status_code=200 if db_status == "ok" else 503)
