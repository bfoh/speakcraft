import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


def test_health_contract_without_external_services() -> None:
    with TestClient(create_app(Settings(docs_enabled=False))) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {
            "status": "ok",
            "service": "speakcraft-api",
            "version": "0.1.0",
        }
        assert client.get("/docs").status_code == 404
        assert client.get("/openapi.json").status_code == 404


def test_opt_in_documentation_matches_response_schema() -> None:
    with TestClient(create_app(Settings(docs_enabled=True))) as client:
        assert client.get("/docs").status_code == 200
        schema = client.get("/openapi.json").json()
        assert set(schema["paths"]) == {
            "/health",
            "/v1/speech/transcribe",
            "/v1/speech/evaluate",
            "/v1/kora/respond",
        }
        assert (
            schema["components"]["schemas"]["HealthResponse"]["properties"]["status"][
                "const"
            ]
            == "ok"
        )


@pytest.mark.parametrize("path", ["/v1/assessment/start"])
def test_future_ai_routes_are_not_fake_integrations(path: str) -> None:
    with TestClient(create_app(Settings(docs_enabled=False))) as client:
        assert client.post(path, json={}).status_code == 404


def test_settings_use_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("SPEAKCRAFT_DOCS_ENABLED", "true")
    assert Settings().docs_enabled is True
