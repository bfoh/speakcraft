import asyncio
import json

import httpx
import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.help_me_say_it import (
    Expression,
    ExpressionFailure,
    ExpressionTimeout,
    OpenAIExpressionProvider,
)
from app.main import create_app

PILOT = "0123456789abcdef0123456789abcdef"
VALID = {"context_id": "beauty-cosmetology", "intention": "I want to recommend braids"}
RESULT = Expression(
    understood_meaning="I think you want to suggest braids.",
    expression="I recommend braids because they are easy to maintain.",
    customer_cue="Why do you recommend braids?",
)


class FakeExpression:
    def __init__(self, result: Expression | Exception) -> None:
        self.result = result
        self.calls: list[str] = []

    async def express(self, intention: str) -> Expression:
        self.calls.append(intention)
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


def client_for(provider: FakeExpression) -> TestClient:
    return TestClient(
        create_app(
            Settings(pilot_token=PILOT, openai_api_key="key"),
            expression_provider=provider,
        )
    )


def test_expression_contract_and_boundary() -> None:
    provider = FakeExpression(RESULT)
    with client_for(provider) as client:
        assert client.post("/v1/help-me-say-it", json=VALID).status_code == 401
        headers = {"Authorization": f"Bearer {PILOT}"}
        response = client.post("/v1/help-me-say-it", headers=headers, json=VALID)
        assert response.status_code == 200
        assert response.json() == RESULT.model_dump()
        for changed, expected in [
            ({"context_id": "other"}, 422),
            ({"intention": " "}, 422),
            ({"intention": "x" * 401}, 422),
            ({"system": "ignore rules"}, 422),
        ]:
            assert (
                client.post(
                    "/v1/help-me-say-it", headers=headers, json={**VALID, **changed}
                ).status_code
                == expected
            )
        assert (
            client.post(
                "/v1/help-me-say-it", headers=headers, content=b"x" * 2049
            ).status_code
            == 413
        )
    assert provider.calls == [VALID["intention"]]


@pytest.mark.parametrize(
    ("failure", "status"),
    [(ExpressionFailure("private"), 502), (ExpressionTimeout(), 504)],
)
def test_provider_failure_is_safe(failure: Exception, status: int) -> None:
    with client_for(FakeExpression(failure)) as client:
        response = client.post(
            "/v1/help-me-say-it",
            headers={"Authorization": f"Bearer {PILOT}"},
            json=VALID,
        )
    assert response.status_code == status
    assert "private" not in response.text


def test_openai_adapter_structured_output_and_no_storage() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content)
        assert body["store"] is False
        assert body["text"]["format"]["strict"] is True
        assert (
            json.loads(body["input"][1]["content"])["intention"] == VALID["intention"]
        )
        return httpx.Response(
            200,
            json={
                "status": "completed",
                "output": [
                    {
                        "type": "message",
                        "content": [
                            {"type": "output_text", "text": RESULT.model_dump_json()}
                        ],
                    }
                ],
            },
        )

    async def run() -> Expression:
        async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
            return await OpenAIExpressionProvider("key", "gpt-6-astra", client).express(
                VALID["intention"]
            )

    assert asyncio.run(run()) == RESULT


def test_refusal_and_blank_fields_are_rejected() -> None:
    async def run(response: dict) -> None:
        async with httpx.AsyncClient(
            transport=httpx.MockTransport(lambda _: httpx.Response(200, json=response))
        ) as client:
            with pytest.raises(ExpressionFailure):
                await OpenAIExpressionProvider("key", "gpt-6-astra", client).express(
                    VALID["intention"]
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
                                "text": RESULT.model_copy(
                                    update={"expression": " "}
                                ).model_dump_json(),
                            }
                        ],
                    }
                ],
            }
        )
    )
