from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Non-secret service settings; load server-only configuration here later."""

    model_config = SettingsConfigDict(env_prefix="SPEAKCRAFT_", extra="ignore")
    docs_enabled: bool = False
