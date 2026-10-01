# Sprint 5 validation — first AI Salon scenario

## Source and simulated journey

- Canonical curriculum and byte-identical mobile/backend packaged assets: PASS. The first salon scenario includes goal, customer goal/personality, difficulty, opening, learner objectives, target language, success conditions and turn limit.
- Backend Ruff formatting/lint, strict mypy and pytest: PASS (32 tests). Tests cover auth, scenario authority, bounded alternating history, refusal/malformed output, safe failures, rejection of apparent invented price amounts and `store: false`.
- Backend wheel: PASS; it includes `app/salon.py` and `app/data/alpha.json`.
- Flutter formatting, analysis and tests: PASS (53 tests). Tests cover explicit salon voice actions, customer-role transport, offline retry and the existing Day-1 journeys.
- iOS simulator native journey: PASS on iPhone 16 Pro / iOS 18.4. It used real SQLite and recording with a local HTTP test server for transcription, feedback, Kora and the AI Salon contract. The test confirmed the lesson take survived both dialogue flows. The installed simulator app needed a microphone grant before the passing run.
- Android debug APK and iOS simulator debug app: PASS.
- `git diff --check` and source secret scan: PASS; only a commented key placeholder is present.

## Product quality gate

**BLOCKED for a real learner pilot.** No non-committed OpenAI key or consented learner recordings were available. Contract and UI tests cannot establish natural customer behavior, transcription accuracy or teaching quality. A Ghanaian educator should review representative exchanges. Both physical devices still need microphone, interruption, audio-route and accessibility checks when connected.

The first scenario has no real price or booking capability. The backend rejects apparent amount-bearing customer responses, but semantic review remains necessary. The shared pilot token is internal-only; public access needs per-learner auth, rate limits and provider retention review.
