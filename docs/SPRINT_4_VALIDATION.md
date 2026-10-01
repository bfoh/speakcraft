# Sprint 4 validation — Day-1 Kora dialogue

## Source and simulated journey

- Canonical five-day curriculum and byte-identical mobile/backend assets: PASS.
- Backend Ruff formatting/lint, strict mypy and pytest: PASS (26 tests). Coverage includes pilot authorization, authored goal and opening, bounded turn history, provider refusal, safe errors, strict output and `store: false`.
- Backend wheel: PASS; the built wheel contains `app/conversation.py` and `app/data/alpha.json`.
- Flutter formatting, static analysis and tests: PASS (45 tests). These cover a spoken exchange, explicit send, offline retry, code replacement, stale responses and enlarged text on a small screen.
- iOS simulator native journey: PASS on iPhone 16 Pro / iOS 18.4. It exercised SQLite, real native recording, explicit transcription, teaching feedback and a Kora turn through a local HTTP test server. It confirmed that a lesson take survives entering and leaving the separate conversation recorder. The installed simulator app needed a microphone grant before the passing run.
- Android debug APK and iOS simulator debug app: PASS.
- `git diff --check` and source secret scan: PASS. The only key assignment found is a commented placeholder in `backend/.env.example`.

## Product quality gate

**BLOCKED for a real learner pilot.** No non-committed OpenAI key or consented learner recordings were available. Local and mocked tests establish the contract, navigation, state and error handling, not conversation relevance, speed, recognition accuracy or teaching quality. A Ghanaian educator should review representative exchanges, and both physical devices need microphone, interruption, audio-route and accessibility checks when connected.

The shared pilot code is for local/internal testing. Public access requires per-learner authentication, rate limits and reviewed provider retention settings. A stateless request limits turn count in the supplied history but cannot prevent a modified client from starting another exchange; the mobile UI itself ends after three learner turns.
