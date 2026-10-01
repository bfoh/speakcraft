from collections.abc import Awaitable, Callable
from hmac import compare_digest
from typing import Annotated, Literal

from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from pydantic import BaseModel
from starlette.responses import JSONResponse, Response

from app.config import Settings
from app.speech import (
    OpenAITranscriber,
    Transcriber,
    TranscriptionFailure,
    TranscriptionTimeout,
)

MAX_AUDIO_BYTES = 4 * 1024 * 1024


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"
    service: Literal["speakcraft-api"] = "speakcraft-api"
    version: Literal["0.1.0"] = "0.1.0"


class TranscriptResponse(BaseModel):
    transcript: str


def create_app(
    settings: Settings | None = None, transcriber: Transcriber | None = None
) -> FastAPI:
    config = settings or Settings()
    provider = transcriber
    if provider is None and config.speech_ready and config.openai_api_key:
        provider = OpenAITranscriber(config.openai_api_key.get_secret_value())
    application = FastAPI(
        title="SpeakCraft API",
        version="0.1.0",
        docs_url="/docs" if config.docs_enabled else None,
        redoc_url=None,
        openapi_url="/openapi.json" if config.docs_enabled else None,
    )

    @application.middleware("http")
    async def guard_speech_upload(
        request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        if request.url.path == "/v1/speech/transcribe" and request.method == "POST":
            if (
                not config.speech_ready
                or provider is None
                or config.pilot_token is None
            ):
                return JSONResponse(
                    {"detail": "Speech is unavailable"}, status_code=503
                )
            expected = f"Bearer {config.pilot_token.get_secret_value()}"
            authorization = request.headers.get("authorization")
            if authorization is None or not compare_digest(authorization, expected):
                return JSONResponse({"detail": "Access code required"}, status_code=401)
            content_length = request.headers.get("content-length")
            if content_length is not None:
                if not content_length.isdecimal():
                    return JSONResponse({"detail": "Invalid upload"}, status_code=400)
                if int(content_length) > MAX_AUDIO_BYTES + 16 * 1024:
                    return JSONResponse(
                        {"detail": "Recording is too large"}, status_code=413
                    )
        return await call_next(request)

    @application.get("/health", response_model=HealthResponse, tags=["health"])
    def health() -> HealthResponse:
        """Process liveness only; no cloud or database readiness is claimed."""
        return HealthResponse()

    @application.post(
        "/v1/speech/transcribe", response_model=TranscriptResponse, tags=["speech"]
    )
    async def transcribe(
        audio: Annotated[UploadFile, File()],
    ) -> TranscriptResponse:
        if provider is None:  # Defence in depth; the guard rejects this first.
            raise HTTPException(status_code=503, detail="Speech is unavailable")
        if not audio.filename or not audio.filename.lower().endswith(".m4a"):
            raise HTTPException(status_code=400, detail="Invalid recording")
        try:
            payload = await audio.read(MAX_AUDIO_BYTES + 1)
        finally:
            await audio.close()
        if len(payload) > MAX_AUDIO_BYTES:
            raise HTTPException(status_code=413, detail="Recording is too large")
        if len(payload) < 16 or payload[4:8] != b"ftyp":
            raise HTTPException(status_code=400, detail="Invalid recording")
        try:
            return TranscriptResponse(transcript=await provider.transcribe(payload))
        except TranscriptionTimeout as exc:
            raise HTTPException(status_code=504, detail="Speech timed out") from exc
        except TranscriptionFailure as exc:
            raise HTTPException(
                status_code=502, detail="Speech is unavailable"
            ) from exc

    return application


app = create_app()
