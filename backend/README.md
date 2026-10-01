# SpeakCraft API

FastAPI application factory with typed liveness and bounded pilot speech-transcription endpoints. See the root README for environment setup and commands. Optional docs are off by default. Speech needs a server-only `OPENAI_API_KEY` and `SPEAKCRAFT_PILOT_TOKEN`; without both it returns 503. The service does not store uploads or transcripts. The pilot token is not a substitute for learner authentication before public deployment.

`requirements-dev.lock` records the validated Python 3.12 development environment. Install it before installing this package with `--no-deps -e .`. Update dependencies deliberately and rerun formatting, linting, mypy and pytest.
