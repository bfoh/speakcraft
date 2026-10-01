# Sprint 5 — First structured AI Salon scenario

## Goal

Let a learner practise a short, realistic Beauty & Cosmetology customer exchange: a friendly customer wants braids and asks about price. The learner should greet, discover needs and respond honestly without inventing a salon price.

## Context

The Alpha blueprint calls AI Salon a structured simulation and names this as the first difficulty level. Sprint 4 established explicit record → transcribe → send voice dialogue, server-only provider access and a bounded response contract. This slice reuses that interaction pattern with authored customer scenario boundaries.

## Non-goals

No five-level scenario ladder, customer account, real booking, actual price quote, scored scenario completion, live audio streaming, persistent session, adaptive memory or public multi-user API. Formal measurement requires a separate evaluation design.

## User Journey

The learner opens **AI Salon** from Home and sees the goal and a simulated customer's opening. They can hear the customer, record an answer, review the tentative transcript, and explicitly send it. The customer responds in role and asks one relevant follow-up. The exchange ends after at most four learner turns; the learner can try again. Network failure preserves the current take and prior dialogue while the screen remains open.

## Technical Approach

- Author one scenario in canonical curriculum data with scenario goal, customer goal/personality, difficulty, opening, learner objectives, target language, success conditions and turn limit. Validate and package identical assets for Flutter and FastAPI.
- Add a stateless, pilot-protected `POST /v1/salon/respond`. Validate scenario ID and bounded alternating customer/learner history, resolve scenario data server-side and send untrusted history as data to a `SalonProvider` interface. Use Responses strict structured output with `store: false`; validate the short customer reply and optional next question. No model-generated score or claimed success.
- Reuse the shared Flutter voice-dialogue screen/controller with an AI Salon mode and separate provider adapter. Map the UI's dialogue turns to customer/learner roles at the API boundary. Reuse the private dialogue recorder, access code and explicit transcription. The current lesson practice take remains isolated.

## Files / Components

`curriculum/alpha.json`, sync/validation script, backend packaged asset and curriculum lookup; backend salon provider, API and tests; mobile curriculum model, salon HTTP adapter, Home/router/dialogue mode and tests; docs and validation record.

## Data Model

No new learner persistence. The authored scenario is versioned content. Current take, transcript and exchange remain in app memory/cache and are cleared when leaving. Backend stores no session or learner content.

## API Contract

`POST /v1/salon/respond` takes `{"scenario_id":"friendly-braids-price","turns":[{"speaker":"customer","text":"..."},...],"transcript":"..."}` with the internal pilot bearer. `200` returns `{"customer_reply":"...","next_question":"...|null"}`. `400/422` invalid scenario/history, `401` missing/wrong pilot token, `503` unavailable provider, `502/504` provider failure/timeout. The server does not accept a client-authored goal or price. The blueprint's `/salon/start`, `/salon/{session}/turn` and `/complete` shapes are deferred until a genuine session/assessment store exists; a stateless `respond` route is the honest Alpha contract.

## Privacy / Security

Customer exchanges can contain learner details. Send audio only on explicit transcription action and text only on explicit reply action. The backend logs and stores neither. Use `store: false` at the provider boundary, server-only credential, strict input bounds and safe errors. A transcript is untrusted content, never a command to the customer. HTTPS is required outside debug localhost. Public deployment needs per-learner auth, rate limits and retention review.

## Offline Behaviour

Authored scenario/opening and local recording work without connectivity. Transcription and customer replies need the backend. Failure preserves the take and visible dialogue for manual retry; nothing syncs silently.

## Android / iOS Considerations

Use one shared Flutter dialogue screen. Keep current microphone permission/interruption and separate cache behavior. Check small displays, text scaling, touch targets and speech output. Run unit/widget checks and debug builds for both platforms, plus available simulator native journey. Physical-device checks wait for connected devices.

## Milestones

1. Author and validate the first scenario.
2. Implement the bounded customer-role backend API/provider with tests.
3. Add AI Salon mode to the mobile dialogue flow and verify navigation, voice and failure states.
4. Run quality gate, native builds and available simulator test; update docs.

## Acceptance Criteria

- Scenario contains every Kora skill boundary and appears clearly as a simulated customer interaction.
- Learner hears the opening, records, reviews words and sends each reply explicitly.
- Customer stays in scenario and does not claim an actual salon price or assessment result.
- Invalid scenario/history and provider failures never produce a fake customer reply.
- Exchange ends after at most four learner turns; retry and offline recovery remain useful.
- No secret or learner conversation is persisted in mobile build or backend.
- Relevant backend/Flutter checks and Android/iOS builds pass.

## Validation

```sh
python3 scripts/sync_curriculum.py --check
backend/.venv/bin/ruff format --check backend scripts
backend/.venv/bin/ruff check backend scripts
backend/.venv/bin/mypy --config-file backend/pyproject.toml backend/app
backend/.venv/bin/pytest -c backend/pyproject.toml backend/tests
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
flutter test integration_test/foundation_test.dart -d <simulator-id>
```

## Risks / Unknowns

- Structured output constrains shape, not scenario fidelity. Educator review of real exchanges is required.
- There is no authoritative real salon price; Kora must avoid inventing one, and learners should practise an honest response.
- Completed-file dialogue is slower than streaming. A live provider key and consented learner samples are unavailable here.

## Decision Log

- 2026-10-02: Reuse the explicit voice-dialogue pattern and stateless API rather than add an artificial server session. Add a real session API only with durable session/assessment needs.
- 2026-10-02: Map the shared dialogue controller's partner turns to customer/learner roles only in the salon HTTP adapter. Keep scenario goals and customer personality authoritative on the backend.
- 2026-10-02: Reject model customer text with digits or currency markers so an apparent invented price amount never appears as a valid customer reply. The UI also explains that no real salon price is defined.
- 2026-10-02: Limit each spoken dialogue answer to 400 characters so a successful turn can fit in the next bounded history request. A longer transcript gets a learner-friendly shorter-answer message.

## Progress

- [x] Inspect blueprint scenario requirements and Sprint 4 dialogue architecture.
- [x] Authored scenario and bounded backend/provider contract.
- [x] Mobile customer role-play with explicit voice actions and retry.
- [x] Source checks, Android/iOS debug builds, iOS native contract test and documentation.
- [~] Live-provider/educator validation and physical-device checks remain pending until a key, consented samples and connected devices are available.
