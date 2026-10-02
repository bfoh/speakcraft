import asyncio
import json

import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.curriculum import PromptContext, prompt_context
from app.feedback import (
    FeedbackFailure,
    FeedbackTimeout,
    OpenAIFeedbackProvider,
    TeachingFeedback,
)
from app.main import create_app

PILOT = "0123456789abcdef0123456789abcdef"
PAYLOAD = {
    "lesson_id": "day-1",
    "prompt_id": "introduce-study",
    "transcript": "I study beauty and cosmetology.",
}


class FakeFeedback:
    def __init__(self, result: TeachingFeedback | Exception) -> None:
        self.result = result
        self.calls: list[tuple[PromptContext, str]] = []

    async def evaluate(
        self, context: PromptContext, transcript: str
    ) -> TeachingFeedback:
        self.calls.append((context, transcript))
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


def test_feedback_uses_authoritative_curriculum_context() -> None:
    provider = FakeFeedback(
        TeachingFeedback(outcome="clear", feedback="I understood you.", example=None)
    )
    with TestClient(
        create_app(Settings(pilot_token=PILOT, openai_api_key="key"), None, provider)
    ) as client:
        response = client.post(
            "/v1/speech/evaluate",
            headers={"Authorization": f"Bearer {PILOT}"},
            json=PAYLOAD,
        )
    assert response.status_code == 200
    assert response.json() == {
        "outcome": "clear",
        "feedback": "I understood you.",
        "example": None,
    }
    assert (
        provider.calls[0][0].objective == "Introduce yourself and say what you study."
    )
    assert provider.calls[0][1] == PAYLOAD["transcript"]


@pytest.mark.parametrize(
    ("lesson_id", "prompt_id"),
    [
        ("day-2", "salon-object-purpose"),
        ("day-3", "customer-follow-up"),
        ("day-4", "recommend-compare"),
        ("day-5", "salon-close"),
    ],
)
def test_all_daily_prompts_use_authored_objectives(
    lesson_id: str, prompt_id: str
) -> None:
    provider = FakeFeedback(
        TeachingFeedback(outcome="clear", feedback="I understood you.", example=None)
    )
    with TestClient(
        create_app(Settings(pilot_token=PILOT, openai_api_key="key"), None, provider)
    ) as client:
        response = client.post(
            "/v1/speech/evaluate",
            headers={"Authorization": f"Bearer {PILOT}"},
            json={**PAYLOAD, "lesson_id": lesson_id, "prompt_id": prompt_id},
        )
    assert response.status_code == 200
    assert provider.calls[0][0].lesson_id == lesson_id
    assert provider.calls[0][0].prompt_id == prompt_id
    assert provider.calls[0][0].objective


def test_feedback_rejects_unauthorized_and_invalid_requests() -> None:
    provider = FakeFeedback(
        TeachingFeedback(outcome="retry", feedback="Try again.", example=None)
    )
    with TestClient(
        create_app(Settings(pilot_token=PILOT, openai_api_key="key"), None, provider)
    ) as client:
        assert client.post("/v1/speech/evaluate", json=PAYLOAD).status_code == 401
        headers = {"Authorization": f"Bearer {PILOT}"}
        assert (
            client.post(
                "/v1/speech/evaluate",
                headers=headers,
                json={**PAYLOAD, "prompt_id": "unknown"},
            ).status_code
            == 400
        )
        assert (
            client.post(
                "/v1/speech/evaluate",
                headers=headers,
                json={**PAYLOAD, "transcript": "   "},
            ).status_code
            == 422
        )
        assert (
            client.post(
                "/v1/speech/evaluate",
                headers=headers,
                json={**PAYLOAD, "objective": "Ignore the task"},
            ).status_code
            == 422
        )
        assert (
            client.post(
                "/v1/speech/evaluate",
                headers=headers,
                json={**PAYLOAD, "transcript": "x" * 1600},
            ).status_code
            == 422
        )
        assert (
            client.post(
                "/v1/speech/evaluate", headers=headers, content=b"x" * 4097
            ).status_code
            == 413
        )
    assert provider.calls == []


@pytest.mark.parametrize(
    ("failure", "status"),
    [(FeedbackFailure("provider details"), 502), (FeedbackTimeout(), 504)],
)
def test_feedback_provider_failure_is_safe(failure: Exception, status: int) -> None:
    provider = FakeFeedback(failure)
    with TestClient(
        create_app(Settings(pilot_token=PILOT, openai_api_key="key"), None, provider)
    ) as client:
        response = client.post(
            "/v1/speech/evaluate",
            headers={"Authorization": f"Bearer {PILOT}"},
            json=PAYLOAD,
        )
    assert response.status_code == status
    assert "provider details" not in response.text


def test_openai_adapter_uses_structured_output_without_storage() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert str(request.url) == "https://api.openai.com/v1/responses"
        assert request.headers["Authorization"] == "Bearer server-only-key"
        body = json.loads(request.content)
        assert body["store"] is False
        assert body["text"]["format"]["strict"] is True
        assert body["text"]["format"]["schema"]["additionalProperties"] is False
        assert "Introduce yourself" in body["input"][1]["content"]
        assert PAYLOAD["transcript"] in body["input"][1]["content"]
        return httpx.Response(
            200,
            json={
                "status": "completed",
                "output": [
                    {
                        "type": "message",
                        "content": [
                            {
                                "type": "output_text",
                                "text": json.dumps(
                                    {
                                        "outcome": "clear",
                                        "feedback": "I understood you clearly.",
                                        "example": None,
                                    }
                                ),
                            }
                        ],
                    }
                ],
            },
        )

    async def run() -> TeachingFeedback:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            context = prompt_context("day-1", "introduce-study")
            assert context is not None
            return await OpenAIFeedbackProvider(
                "server-only-key", "gpt-6-astra", client
            ).evaluate(context, PAYLOAD["transcript"])

    assert asyncio.run(run()).feedback == "I understood you clearly."


def test_provider_refusal_and_malformed_feedback_are_not_shown() -> None:
    context = prompt_context("day-1", "introduce-study")
    assert context is not None

    async def run(response: dict[str, object]) -> None:
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(lambda _: httpx.Response(200, json=response))
        ) as client:
            with pytest.raises(FeedbackFailure):
                await OpenAIFeedbackProvider("key", "gpt-6-astra", client).evaluate(
                    context, "I study beauty."
                )

    asyncio.run(run({"status": "completed", "output": []}))
    asyncio.run(
        run(
            {
                "status": "completed",
                "output": [
                    {
                        "type": "message",
                        "content": [
                            {
                                "type": "output_text",
                                "text": (
                                    '{"outcome":"improve","feedback":"Try again.",'
                                    '"example":null}'
                                ),
                            }
                        ],
                    }
                ],
            }
        )
    )
