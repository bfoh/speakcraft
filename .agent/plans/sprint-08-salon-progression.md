# Sprint 8 — Day-3 consultation and Day-5 salon conversation

## Goal

Give learners structured customer conversations aligned with the Day-3 greeting/needs objective and Day-5 greeting → needs → questions → recommendation → explanation → closing objective. Learners should be able to complete a bounded dialogue and review what they said, without an unvalidated pass score.

## Context

SpeakCraft already has one difficulty-1 AI Salon scenario, a bounded stateless FastAPI endpoint, real recording/transcription, device speech and open daily practice pages. The provider instructions and mobile route are currently tied to the first braids-and-price scenario. The blueprint calls for a 90-second Day-3 consultation and a fuller Day-5 salon challenge.

## Non-goals

No automated proficiency score, invented salon prices/bookings, arbitrary scenario authoring, low-latency Realtime, persistent recordings or accounts. This sprint offers the conversation practice; validated challenge assessment remains a separate product decision requiring educator review.

## User Journey

From Day 3, the learner opens a welcoming customer consultation, listens to the customer's opening, then greets and asks about needs over several short voice turns. From Day 5, they open a fuller salon exchange with a customer who has a hair-care goal but needs a recommendation. They listen, record, review tentative words and explicitly send each answer. The dialogue ends after its authored turn limit with a transcript summary, and the learner may practise again. Network failure keeps the current take for retry.

## Technical Approach

- Add two structured scenarios to canonical curriculum with goal, customer goal/personality, difficulty, opening, learner objectives, target language, success conditions and turn limit. Validate stable IDs and bounds; copy identical assets to mobile and backend.
- Generalise the salon provider instructions to use the selected scenario instead of hardcoded braids/price text. Keep a universal prohibition on inventing real prices, policies, bookings or private details.
- Allow longer bounded histories at the API boundary while keeping strict alternating roles, authoritative opening, 400-character turn fields and body cap. Preserve `store: false`, auth and safe failures.
- Route distinct scenario IDs to the shared Flutter dialogue screen and controller, with scenario-specific explanatory text and a final review of the exchange. Link the Day-3 and Day-5 lesson pages to their respective scenarios.

## Files / Components

Canonical curriculum and sync validator, backend scenario/provider/API tests, Flutter curriculum/route/dialogue/Home/tests, native simulator journey, docs and quality record.

## Data Model

No new persistent learner data. Customer and learner dialogue stays in memory for the open screen; the backend remains stateless. The authored scenario content is versioned repository data.

## API Contract

Continue `POST /v1/salon/respond` with `{scenario_id, turns, transcript}` and `{customer_reply, next_question}`. Accept only known scenario IDs and an exact authored opening. History is bounded by each scenario's turn limit and a global maximum; unknown or malformed content is rejected before provider access.

## Privacy / Security

Audio is uploaded only for explicit transcription; reviewed text is sent only when the learner chooses Send reply. No conversation is logged or stored. Server-only provider key and internal pilot token remain as before. Keep model output length checks and reject apparent invented numeric prices. Public deployment still needs learner auth/rate limits and provider retention review.

## Offline Behaviour

Authored scenario goals/openings can be read and played offline if device speech is available. Local recording works without the backend. Generated customer turns require connectivity, and failures preserve the take and transcript for explicit retry.

## Android / iOS Considerations

Use the same Flutter screen and audio controls on both. Verify microphone permissions, lifecycle interruptions, audio routes, small screens and text scaling. Run Android and iOS simulator debug builds; device tests wait until connected.

## Milestones

1. Add and validate Day-3 and Day-5 authored scenarios.
2. Generalise backend customer responses with strict multi-scenario tests.
3. Open scenario-specific mobile journeys and review states.
4. Run quality gate, platform builds and documentation update.

## Acceptance Criteria

- Day 3 launches an authored customer consultation and Day 5 launches a fuller, distinct salon conversation.
- Each learner reply is recorded, transcribed and explicitly sent; the customer remains in the selected scenario for its bounded turns.
- The end screen shows the exchange and practice completion without claiming a score or validated mastery.
- Unknown scenario IDs, altered opening text, overlong history and malformed provider output fail safely.
- Offline/provider failure leaves the current response available for retry.
- Flutter/backend tests and Android/iOS debug builds pass.

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

- The blueprint specifies outcomes more than exact dialogue. Authored scenario text and provider behavior need Ghanaian educator review.
- A 90-second consultation is an overall exchange goal, not a single recording: each take remains capped at 60 seconds. We will not claim duration-based completion without measuring it.
- Local Xcode simulator builds are currently stalled by a host keychain credential issue; CI can verify generic iOS compilation, while native journey may wait for host repair or connected devices.

## Decision Log

- 2026-10-02: Reuse the stateless salon contract and screen. Distinct scenario IDs carry the learning boundaries; no new endpoint or database is needed.
- 2026-10-02: Allow at most six learner turns and an 8 KiB request body, then validate the selected scenario's tighter limit. Keep each transcript turn at 400 characters.
- 2026-10-02: Completion means the bounded dialogue ended. The final screen shows the exchange but no score or inferred mastery.

## Progress

- [x] Read the blueprint's Day-3 and Day-5 objectives and inspect the first Salon slice.
- [x] Author and validate three scenarios in canonical curriculum.
- [x] Generalise backend provider/contract and mobile routes/dialogue.
- [x] Backend and Flutter test suites pass.
- [x] Android debug build, source quality checks and backend wheel packaging pass.
- [~] Generic iOS CI build and final quality record. Native simulator test is blocked by local Xcode.
- [ ] Live provider, educator and physical-device review before pilot.
