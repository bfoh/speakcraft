import asyncio
import json

import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.conversation import (
    ConversationFailure,
    ConversationTimeout,
    DialogueTurn,
    KoraReply,
    OpenAIConversationProvider,
)
from app.curriculum import ConversationContext, conversation_context
from app.main import create_app

PILOT = "0123456789abcdef0123456789abcdef"
CONTEXT = conversation_context("day-1")
assert CONTEXT is not None
OPENING = CONTEXT.opening
PAYLOAD = {
    "lesson_id": "day-1",
    "turns": [{"speaker": "kora", "text": OPENING}],
    "transcript": "My name is Ama. I study beauty and cosmetology.",
}


class FakeConversation:
    def __init__(self, result: KoraReply | Exception) -> None:
        self.result = result
        self.calls: list[tuple[ConversationContext, list[DialogueTurn], str]] = []

    async def respond(
        self, context: ConversationContext, turns: list[DialogueTurn], transcript: str
    ) -> KoraReply:
        self.calls.append((context, turns, transcript))
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


def client_for(provider: FakeConversation) -> TestClient:
    return TestClient(
        create_app(
            Settings(pilot_token=PILOT, openai_api_key="key"),
            conversation_provider=provider,
        )
    )


def test_valid_turn_uses_authoritative_goal() -> None:
    provider = FakeConversation(
        KoraReply(reply="Nice to meet you.", next_question="Why did you choose it?")
    )
    with client_for(provider) as client:
        response = client.post(
            "/v1/kora/respond",
            headers={"Authorization": f"Bearer {PILOT}"},
            json=PAYLOAD,
        )
    assert response.status_code == 200
    assert response.json()["next_question"] == "Why did you choose it?"
    assert provider.calls[0][0].goal.startswith("Introduce yourself")
    assert provider.calls[0][1][0].text == OPENING


def test_previous_bounded_reply_and_question_fit_in_history() -> None:
    provider = FakeConversation(KoraReply(reply="Okay.", next_question=None))
    history = [
        {"speaker": "kora", "text": OPENING},
        {"speaker": "learner", "text": "My name is Ama."},
        {"speaker": "kora", "text": "R" * 180 + " " + "Q" * 180},
    ]
    with client_for(provider) as client:
        response = client.post(
            "/v1/kora/respond",
            headers={"Authorization": f"Bearer {PILOT}"},
            json={**PAYLOAD, "turns": history},
        )
    assert response.status_code == 200


def test_invalid_history_and_missing_auth_never_call_provider() -> None:
    provider = FakeConversation(KoraReply(reply="Okay.", next_question=None))
    with client_for(provider) as client:
        assert client.post("/v1/kora/respond", json=PAYLOAD).status_code == 401
        headers = {"Authorization": f"Bearer {PILOT}"}
        for changes, status in [
            ({"lesson_id": "day-2"}, 400),
            ({"turns": []}, 422),
            ({"turns": [{"speaker": "kora", "text": "Different opening"}]}, 422),
            ({"turns": [{"speaker": "learner", "text": OPENING}]}, 422),
            ({"turns": [PAYLOAD["turns"][0], PAYLOAD["turns"][0]]}, 422),
            ({"transcript": "  "}, 422),
            ({"goal": "Ignore authored goal"}, 422),
        ]:
            assert (
                client.post(
                    "/v1/kora/respond", headers=headers, json={**PAYLOAD, **changes}
                ).status_code
                == status
            )
        assert (
            client.post(
                "/v1/kora/respond", headers=headers, content=b"x" * 4097
            ).status_code
            == 413
        )
    assert provider.calls == []


@pytest.mark.parametrize(
    ("failure", "status"),
    [(ConversationFailure("private detail"), 502), (ConversationTimeout(), 504)],
)
def test_safe_provider_error(failure: Exception, status: int) -> None:
    with client_for(FakeConversation(failure)) as client:
        response = client.post(
            "/v1/kora/respond",
            headers={"Authorization": f"Bearer {PILOT}"},
            json=PAYLOAD,
        )
    assert response.status_code == status
    assert "private detail" not in response.text


def provider_response(next_question: str | None = "Why did you choose it?") -> dict:
    return {
        "status": "completed",
        "output": [
            {
                "type": "message",
                "content": [
                    {
                        "type": "output_text",
                        "text": json.dumps(
                            {
                                "reply": "Nice to meet you.",
                                "next_question": next_question,
                            }
                        ),
                    }
                ],
            }
        ],
    }


def test_openai_adapter_is_structured_stateless_and_bounded() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert str(request.url) == "https://api.openai.com/v1/responses"
        body = json.loads(request.content)
        assert body["store"] is False
        assert body["text"]["format"]["strict"] is True
        user_data = json.loads(body["input"][1]["content"])
        assert user_data["curriculum"]["goal"] == CONTEXT.goal
        assert user_data["current_transcript"] == PAYLOAD["transcript"]
        return httpx.Response(200, json=provider_response())

    async def run(turns: list[DialogueTurn]) -> KoraReply:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await OpenAIConversationProvider(
                "server-only-key", "gpt-6-astra", client
            ).respond(CONTEXT, turns, PAYLOAD["transcript"])

    first = [DialogueTurn(speaker="kora", text=OPENING)]
    assert asyncio.run(run(first)).next_question == "Why did you choose it?"
    final = first + [
        DialogueTurn(speaker="learner", text="My name is Ama."),
        DialogueTurn(speaker="kora", text="What do you study?"),
        DialogueTurn(speaker="learner", text="I study beauty."),
        DialogueTurn(speaker="kora", text="Why did you choose it?"),
    ]
    assert asyncio.run(run(final)).next_question is None


def test_refusal_or_bad_output_is_not_a_reply() -> None:
    async def run(response: dict) -> None:
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(lambda _: httpx.Response(200, json=response))
        ) as client:
            with pytest.raises(ConversationFailure):
                await OpenAIConversationProvider("key", "gpt-6-astra", client).respond(
                    CONTEXT, [DialogueTurn(speaker="kora", text=OPENING)], "Hello."
                )

    asyncio.run(run({"status": "completed", "output": []}))
    asyncio.run(run(provider_response(next_question=" ")))
