from collections.abc import Awaitable, Callable
from hmac import compare_digest
from typing import Annotated, Literal

from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from pydantic import BaseModel, ConfigDict, Field
from starlette.responses import JSONResponse, Response

from app.config import Settings
from app.conversation import (
    ConversationFailure,
    ConversationProvider,
    ConversationTimeout,
    DialogueTurn,
    KoraReply,
    OpenAIConversationProvider,
)
from app.curriculum import conversation_context, prompt_context
from app.feedback import (
    FeedbackFailure,
    FeedbackProvider,
    FeedbackTimeout,
    OpenAIFeedbackProvider,
    TeachingFeedback,
)
from app.speech import (
    OpenAITranscriber,
    Transcriber,
    TranscriptionFailure,
    TranscriptionTimeout,
)

MAX_AUDIO_BYTES = 4 * 1024 * 1024
MAX_FEEDBACK_BODY_BYTES = 4096
MAX_CONVERSATION_BODY_BYTES = 4096


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"
    service: Literal["speakcraft-api"] = "speakcraft-api"
    version: Literal["0.1.0"] = "0.1.0"


class TranscriptResponse(BaseModel):
    transcript: str


class FeedbackRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    lesson_id: str = Field(min_length=1, max_length=80)
    prompt_id: str = Field(min_length=1, max_length=80)
    transcript: str = Field(min_length=1, max_length=1500)


class ConversationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    lesson_id: str = Field(min_length=1, max_length=80)
    turns: list[DialogueTurn] = Field(min_length=1, max_length=5)
    transcript: str = Field(min_length=1, max_length=1500)


def create_app(
    settings: Settings | None = None,
    transcriber: Transcriber | None = None,
    feedback_provider: FeedbackProvider | None = None,
    conversation_provider: ConversationProvider | None = None,
) -> FastAPI:
    config = settings or Settings()
    provider = transcriber
    if provider is None and config.speech_ready and config.openai_api_key:
        provider = OpenAITranscriber(config.openai_api_key.get_secret_value())
    evaluator = feedback_provider
    if evaluator is None and config.speech_ready and config.openai_api_key:
        evaluator = OpenAIFeedbackProvider(
            config.openai_api_key.get_secret_value(), config.feedback_model
        )
    conversation = conversation_provider
    if conversation is None and config.speech_ready and config.openai_api_key:
        conversation = OpenAIConversationProvider(
            config.openai_api_key.get_secret_value(), config.feedback_model
        )
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
        path = request.url.path
        if (
            path
            in {
                "/v1/speech/transcribe",
                "/v1/speech/evaluate",
                "/v1/kora/respond",
            }
            and request.method == "POST"
        ):
            active_provider = {
                "/v1/speech/transcribe": provider,
                "/v1/speech/evaluate": evaluator,
                "/v1/kora/respond": conversation,
            }[path]
            if (
                not config.speech_ready
                or active_provider is None
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
                maximum = (
                    MAX_AUDIO_BYTES + 16 * 1024
                    if path == "/v1/speech/transcribe"
                    else max(MAX_FEEDBACK_BODY_BYTES, MAX_CONVERSATION_BODY_BYTES)
                )
                if int(content_length) > maximum:
                    return JSONResponse(
                        {"detail": "Request is too large"}, status_code=413
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

    @application.post(
        "/v1/speech/evaluate", response_model=TeachingFeedback, tags=["speech"]
    )
    async def evaluate(request: Request) -> TeachingFeedback:
        if evaluator is None:
            raise HTTPException(status_code=503, detail="Feedback is unavailable")
        body = bytearray()
        async for chunk in request.stream():
            body.extend(chunk)
            if len(body) > MAX_FEEDBACK_BODY_BYTES:
                raise HTTPException(status_code=413, detail="Request is too large")
        try:
            payload = FeedbackRequest.model_validate_json(body)
        except ValueError as exc:
            raise HTTPException(
                status_code=422, detail="Invalid feedback request"
            ) from exc
        transcript = payload.transcript.strip()
        if not transcript:
            raise HTTPException(status_code=422, detail="Transcript is empty")
        context = prompt_context(payload.lesson_id, payload.prompt_id)
        if context is None:
            raise HTTPException(status_code=400, detail="Unknown lesson prompt")
        try:
            return await evaluator.evaluate(context, transcript)
        except FeedbackTimeout as exc:
            raise HTTPException(status_code=504, detail="Feedback timed out") from exc
        except FeedbackFailure as exc:
            raise HTTPException(
                status_code=502, detail="Feedback is unavailable"
            ) from exc

    @application.post("/v1/kora/respond", response_model=KoraReply, tags=["kora"])
    async def respond(request: Request) -> KoraReply:
        if conversation is None:
            raise HTTPException(status_code=503, detail="Kora is unavailable")
        body = bytearray()
        async for chunk in request.stream():
            body.extend(chunk)
            if len(body) > MAX_CONVERSATION_BODY_BYTES:
                raise HTTPException(status_code=413, detail="Request is too large")
        try:
            payload = ConversationRequest.model_validate_json(body)
        except ValueError as exc:
            raise HTTPException(
                status_code=422, detail="Invalid conversation request"
            ) from exc
        context = conversation_context(payload.lesson_id)
        if context is None:
            raise HTTPException(status_code=400, detail="Unknown lesson")
        turns = payload.turns
        if (
            len(turns) % 2 != 1
            or len(turns) > 2 * context.turn_limit - 1
            or turns[0].speaker != "kora"
            or turns[0].text != context.opening
            or any(
                turn.speaker != ("kora" if index % 2 == 0 else "learner")
                or not turn.text.strip()
                for index, turn in enumerate(turns)
            )
            or not payload.transcript.strip()
        ):
            raise HTTPException(status_code=422, detail="Invalid conversation")
        try:
            return await conversation.respond(
                context, turns, payload.transcript.strip()
            )
        except ConversationTimeout as exc:
            raise HTTPException(status_code=504, detail="Kora timed out") from exc
        except ConversationFailure as exc:
            raise HTTPException(status_code=502, detail="Kora is unavailable") from exc

    return application


app = create_app()
