from pydantic import Field, SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Non-secret service settings; load server-only configuration here later."""

    model_config = SettingsConfigDict(
        env_prefix="SPEAKCRAFT_", extra="ignore", populate_by_name=True
    )
    docs_enabled: bool = False
    pilot_token: SecretStr | None = None
    openai_api_key: SecretStr | None = Field(
        default=None, validation_alias="OPENAI_API_KEY"
    )
    feedback_model: str = "gpt-6-astra"

    @field_validator("pilot_token")
    @classmethod
    def require_long_pilot_token(cls, value: SecretStr | None) -> SecretStr | None:
        if value is not None and len(value.get_secret_value()) < 32:
            raise ValueError("Pilot token must have at least 32 characters")
        return value

    @property
    def speech_ready(self) -> bool:
        return bool(self.pilot_token and self.openai_api_key)
