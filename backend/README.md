# SpeakCraft API

FastAPI application factory with typed liveness, bounded pilot speech transcription and prompt-bound Kora teaching feedback. See the root README for environment setup and commands. Optional docs are off by default. Speech and feedback need a server-only `OPENAI_API_KEY` and `SPEAKCRAFT_PILOT_TOKEN`; without both they return 503. `SPEAKCRAFT_FEEDBACK_MODEL` sets the server-side feedback model. The service does not store uploads, transcripts or generated feedback. The pilot token is not a substitute for learner authentication before public deployment.

`requirements-dev.lock` records the validated Python 3.12 development environment. Install it before installing this package with `--no-deps -e .`. Update dependencies deliberately and rerun formatting, linting, mypy and pytest.
