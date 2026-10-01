# Sprint 3 validation — Day-1 teaching feedback

## Source and simulated journey

- Canonical curriculum validation and mobile/backend asset equality: PASS.
- Backend Ruff formatting/lint, mypy and pytest: PASS (20 tests). Tests include authentication, curriculum authority, malformed output, refusal, provider failure and `store: false`.
- Flutter formatting, analysis and tests: PASS. Tests include explicit learner action, feedback audio, offline retry and stale result invalidation.
- iOS simulator native journey: PASS on iPhone 16 Pro / iOS 18.4. It exercised real SQLite, native microphone recording, a local transcription HTTP server and the feedback HTTP contract. The simulator microphone permission was granted before the passing run.
- Android and iOS debug builds: PASS.
- `git diff --check` and source secret scan: PASS. The only `OPENAI_API_KEY=` match is the commented placeholder in `backend/.env.example`.

## Product quality gate

**BLOCKED for a real learner pilot.** No non-committed OpenAI key or consented learner recordings are available in this environment. The tests verify schema, transport, state and error handling, but cannot establish transcription accuracy or whether Kora's advice is correct, brief, culturally appropriate and limited to one useful improvement. An educator should review representative Ghanaian-accented attempts on Android and iOS before pilot use. Physical-device microphone, interruption and accessibility checks remain pending until devices are connected.

The internal shared pilot code is suitable only for local testing. Public access also needs learner authentication, rate limits and reviewed provider retention settings.
