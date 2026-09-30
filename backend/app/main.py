from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel

from app.config import Settings


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"
    service: Literal["speakcraft-api"] = "speakcraft-api"
    version: Literal["0.1.0"] = "0.1.0"


def create_app(settings: Settings | None = None) -> FastAPI:
    config = settings or Settings()
    application = FastAPI(
        title="SpeakCraft API",
        version="0.1.0",
        docs_url="/docs" if config.docs_enabled else None,
        redoc_url=None,
        openapi_url="/openapi.json" if config.docs_enabled else None,
    )

    @application.get("/health", response_model=HealthResponse, tags=["health"])
    def health() -> HealthResponse:
        """Process liveness only; no cloud or database readiness is claimed."""
        return HealthResponse()

    return application


app = create_app()
