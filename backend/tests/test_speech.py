import asyncio
from typing import Literal

import httpx
import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.config import Settings
from app.main import MAX_AUDIO_BYTES, create_app
from app.speech import OpenAITranscriber, TranscriptionFailure, TranscriptionTimeout

M4A = b"\x00\x00\x00\x18ftypM4A " + b"\x00" * 32
PILOT = "0123456789abcdef0123456789abcdef"


class FakeTranscriber:
    def __init__(self, result: str | Exception = "My name is Ama.") -> None:
        self.result = result
        self.calls: list[bytes] = []

    async def transcribe(self, audio: bytes) -> str:
        self.calls.append(audio)
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


def client_for(
    provider: FakeTranscriber, *, token: str | None = PILOT, key: str | None = "key"
) -> TestClient:
    return TestClient(
        create_app(Settings(pilot_token=token, openai_api_key=key), provider)
    )


def send(
    client: TestClient,
    data: bytes = M4A,
    *,
    token: str | None = PILOT,
    filename: str = "attempt.m4a",
) -> httpx.Response:
    return client.post(
        "/v1/speech/transcribe",
        headers={"Authorization": f"Bearer {token}"} if token else {},
        files={"audio": (filename, data, "audio/mp4")},
    )


def test_authorized_transcript_and_empty_speech() -> None:
    provider = FakeTranscriber()
    with client_for(provider) as client:
        response = send(client)
        assert response.status_code == 200
        assert response.json() == {"transcript": "My name is Ama."}
        assert provider.calls == [M4A]
        provider.result = ""
        assert send(client).json() == {"transcript": ""}


def test_speech_disabled_without_both_server_secrets() -> None:
    provider = FakeTranscriber()
    for token, key in [(None, "key"), (PILOT, None)]:
        with client_for(provider, token=token, key=key) as client:
            assert send(client).status_code == 503
    assert provider.calls == []


def test_access_token_required_before_provider_call() -> None:
    provider = FakeTranscriber()
    with client_for(provider) as client:
        assert send(client, token=None).status_code == 401
        assert send(client, token="wrong").status_code == 401
        assert send(client, M4A + b"0" * MAX_AUDIO_BYTES, token=None).status_code == 401
    assert provider.calls == []


def test_short_pilot_token_is_rejected_at_configuration() -> None:
    with pytest.raises(ValidationError):
        Settings(pilot_token="short", openai_api_key="key")


def test_server_secrets_load_only_from_environment(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("OPENAI_API_KEY", "provider-secret")
    monkeypatch.setenv("SPEAKCRAFT_PILOT_TOKEN", PILOT)
    settings = Settings()
    assert settings.speech_ready
    assert settings.openai_api_key is not None
    assert settings.openai_api_key.get_secret_value() == "provider-secret"
    assert "provider-secret" not in repr(settings)


def test_bad_or_large_audio_never_reaches_provider() -> None:
    provider = FakeTranscriber()
    with client_for(provider) as client:
        assert send(client, b"", filename="attempt.m4a").status_code == 400
        assert send(client, b"not audio" + b"0" * 20).status_code == 400
        assert send(client, M4A, filename="attempt.wav").status_code == 400
        assert send(client, M4A + b"0" * MAX_AUDIO_BYTES).status_code == 413
    assert provider.calls == []


def test_provider_failures_have_safe_distinct_responses() -> None:
    for failure, status in [
        (TranscriptionFailure("provider details"), 502),
        (TranscriptionTimeout(), 504),
    ]:
        provider = FakeTranscriber(failure)
        with client_for(provider) as client:
            response = send(client)
            assert response.status_code == status
            assert "provider details" not in response.text


def test_openai_adapter_uses_documented_file_endpoint() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert str(request.url) == "https://api.openai.com/v1/audio/transcriptions"
        assert request.headers["Authorization"] == "Bearer server-only-key"
        body = request.read()
        assert b"gpt-transcribe" in body
        assert b"attempt.m4a" in body
        assert M4A in body
        return httpx.Response(200, json={"text": "  My name is Ama.  "})

    async def run() -> None:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            provider = OpenAITranscriber("server-only-key", client)
            assert await provider.transcribe(M4A) == "My name is Ama."

    asyncio.run(run())


def test_openai_adapter_rejects_malformed_provider_response() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"unexpected": "field"})

    async def run() -> Literal[True]:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            provider = OpenAITranscriber("server-only-key", client)
            try:
                await provider.transcribe(M4A)
            except TranscriptionFailure:
                return True
            raise AssertionError("Expected failure for missing transcript field")

    assert asyncio.run(run())
