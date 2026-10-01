"""Speech provider boundary. No learner audio or transcript is logged or stored."""

from typing import Protocol

import httpx


class TranscriptionFailure(Exception):
    """The speech provider did not produce a usable response."""


class TranscriptionTimeout(TranscriptionFailure):
    """The speech provider exceeded the request deadline."""


class Transcriber(Protocol):
    async def transcribe(self, audio: bytes) -> str: ...


class OpenAITranscriber:
    """Send a completed recording to OpenAI's file transcription endpoint."""

    def __init__(self, api_key: str, client: httpx.AsyncClient | None = None) -> None:
        self._api_key = api_key
        self._client = client

    async def transcribe(self, audio: bytes) -> str:
        client = self._client or httpx.AsyncClient(timeout=30.0)
        try:
            response = await client.post(
                "https://api.openai.com/v1/audio/transcriptions",
                headers={"Authorization": f"Bearer {self._api_key}"},
                data={"model": "gpt-transcribe"},
                files={"file": ("attempt.m4a", audio, "audio/mp4")},
            )
            response.raise_for_status()
            data = response.json()
            if not isinstance(data, dict):
                raise TranscriptionFailure("Malformed provider response")
            text: object = data.get("text")
            if not isinstance(text, str):
                raise TranscriptionFailure("Malformed provider response")
            return text.strip()
        except httpx.TimeoutException as exc:
            raise TranscriptionTimeout from exc
        except (httpx.HTTPError, ValueError) as exc:
            raise TranscriptionFailure from exc
        finally:
            if self._client is None:
                await client.aclose()
