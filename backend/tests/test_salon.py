import asyncio
import json

import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.curriculum import SalonContext, salon_context
from app.main import create_app
from app.salon import (
    CustomerReply,
    OpenAISalonProvider,
    SalonFailure,
    SalonTimeout,
    SalonTurn,
)

PILOT = "0123456789abcdef0123456789abcdef"
CONTEXT = salon_context("friendly-braids-price")
assert CONTEXT is not None
PAYLOAD = {
    "scenario_id": CONTEXT.scenario_id,
    "turns": [{"speaker": "customer", "text": CONTEXT.customer_opening}],
    "transcript": "Welcome. What kind of braids would you like?",
}


class FakeSalon:
    def __init__(self, result: CustomerReply | Exception) -> None:
        self.result = result
        self.calls: list[tuple[SalonContext, list[SalonTurn], str]] = []

    async def respond(
        self, context: SalonContext, turns: list[SalonTurn], transcript: str
    ) -> CustomerReply:
        self.calls.append((context, turns, transcript))
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


def client_for(provider: FakeSalon) -> TestClient:
    return TestClient(
        create_app(
            Settings(pilot_token=PILOT, openai_api_key="key"), salon_provider=provider
        )
    )


def test_valid_scenario_uses_authored_boundaries() -> None:
    provider = FakeSalon(
        CustomerReply(
            customer_reply="Thank you. I like medium braids.",
            next_question="Could you check the price?",
        )
    )
    with client_for(provider) as client:
        response = client.post(
            "/v1/salon/respond",
            headers={"Authorization": f"Bearer {PILOT}"},
            json=PAYLOAD,
        )
    assert response.status_code == 200
    assert response.json()["next_question"] == "Could you check the price?"
    assert provider.calls[0][0].difficulty == 1
    assert provider.calls[0][0].customer_goal.startswith("The customer wants braids")


def test_invalid_input_and_auth_never_call_provider() -> None:
    provider = FakeSalon(CustomerReply(customer_reply="Okay.", next_question=None))
    with client_for(provider) as client:
        assert client.post("/v1/salon/respond", json=PAYLOAD).status_code == 401
        headers = {"Authorization": f"Bearer {PILOT}"}
        for changes, status in [
            ({"scenario_id": "unknown"}, 400),
            ({"turns": []}, 422),
            ({"turns": [{"speaker": "customer", "text": "Changed opening"}]}, 422),
            (
                {"turns": [{"speaker": "learner", "text": CONTEXT.customer_opening}]},
                422,
            ),
            ({"transcript": "  "}, 422),
            ({"transcript": "x" * 401}, 422),
            ({"price": "100"}, 422),
        ]:
            assert (
                client.post(
                    "/v1/salon/respond", headers=headers, json={**PAYLOAD, **changes}
                ).status_code
                == status
            )
        assert (
            client.post(
                "/v1/salon/respond", headers=headers, content=b"x" * 4097
            ).status_code
            == 413
        )
    assert provider.calls == []


@pytest.mark.parametrize(
    ("failure", "status"),
    [(SalonFailure("private detail"), 502), (SalonTimeout(), 504)],
)
def test_provider_failure_is_safe(failure: Exception, status: int) -> None:
    with client_for(FakeSalon(failure)) as client:
        response = client.post(
            "/v1/salon/respond",
            headers={"Authorization": f"Bearer {PILOT}"},
            json=PAYLOAD,
        )
    assert response.status_code == status
    assert "private detail" not in response.text


def response_data() -> dict:
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
                                "customer_reply": "I like medium braids.",
                                "next_question": "Could you check the price?",
                            }
                        ),
                    }
                ],
            }
        ],
    }


def test_openai_adapter_uses_scenario_and_disables_storage() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert str(request.url) == "https://api.openai.com/v1/responses"
        body = json.loads(request.content)
        assert body["store"] is False
        assert body["text"]["format"]["strict"] is True
        user_data = json.loads(body["input"][1]["content"])
        assert user_data["scenario"]["customer_goal"] == CONTEXT.customer_goal
        assert user_data["current_transcript"] == PAYLOAD["transcript"]
        return httpx.Response(200, json=response_data())

    async def run(turns: list[SalonTurn]) -> CustomerReply:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await OpenAISalonProvider(
                "server-only-key", "gpt-6-astra", client
            ).respond(CONTEXT, turns, PAYLOAD["transcript"])

    first = [SalonTurn(speaker="customer", text=CONTEXT.customer_opening)]
    assert asyncio.run(run(first)).next_question == "Could you check the price?"
    final = first + [
        SalonTurn(speaker="learner", text="Hello."),
        SalonTurn(speaker="customer", text="I want braids."),
        SalonTurn(speaker="learner", text="What kind?"),
        SalonTurn(speaker="customer", text="Medium braids."),
        SalonTurn(speaker="learner", text="Let me check price."),
        SalonTurn(speaker="customer", text="Thank you."),
    ]
    assert asyncio.run(run(final)).next_question is None


def test_refusal_and_malformed_output_are_not_customer_replies() -> None:
    async def run(response: dict) -> None:
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(lambda _: httpx.Response(200, json=response))
        ) as client:
            with pytest.raises(SalonFailure):
                await OpenAISalonProvider("key", "gpt-6-astra", client).respond(
                    CONTEXT,
                    [SalonTurn(speaker="customer", text=CONTEXT.customer_opening)],
                    "Welcome.",
                )

    asyncio.run(run({"status": "completed", "output": []}))
    malformed = response_data()
    malformed["output"][0]["content"][0]["text"] = (
        '{"customer_reply":" ","next_question":null}'
    )
    asyncio.run(run(malformed))
    priced = response_data()
    priced["output"][0]["content"][0]["text"] = json.dumps(
        {"customer_reply": "That costs 100 cedis.", "next_question": None}
    )
    asyncio.run(run(priced))
