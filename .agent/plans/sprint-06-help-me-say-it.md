# Sprint 6 — Help Me Say It micro-lesson

## Goal

Help a Beauty & Cosmetology learner turn an intended meaning into simple useful English, hear it, repeat it and use it once in a short salon role-play. This follows the blueprint's signature experience rather than stopping at translation.

## Context

SpeakCraft has native recording, explicit transcription, device speech, an authenticated provider boundary and a first AI Salon scenario. The Kora skill specifies intention → careful meaning inference → level-appropriate expression → audio model → repeat → short retrieval/role-play. English is currently the only reviewed support language.

## Non-goals

No local-language translation, automatic proficiency level, pronunciation score, voice cloning, persistent phrase bank, spaced review, arbitrary chatbot or account. The learner's intention and generated phrase remain transient. Broader learner adaptation needs later design and consent.

## User Journey

The learner opens **Help Me Say It** and records what they want to tell a customer. They review the tentative transcript and explicitly ask Kora for useful English. Kora shows one short expression, with a listen control and a brief meaning confirmation. The learner records a repetition and sees what recognition heard, then hears a short customer cue and records one reply using the expression. The app does not claim a pass or score. The learner can retry each recording and start over.

## Technical Approach

- Add an authenticated, bounded `POST /v1/help-me-say-it` behind FastAPI. Send only the reviewed intention transcript and an authored Beauty & Cosmetology context identifier. The backend instructs a provider to infer meaning carefully, avoid invented personal details and produce strict structured output: one short expression, a brief meaning confirmation and one simple customer cue. Validate lengths and shape; use `store: false` and safe errors.
- Add a provider-neutral Flutter HTTP adapter and controller. Reuse native recording/transcription and device speech. Keep three stages explicit: intention, repeat, role-play. The current stage and generated text stay in memory. Only a learner action uploads audio/text. Recordings use a separate private temporary area or a carefully owned dialogue recorder so existing Day-1 work remains untouched.
- Show all words on screen with large controls and useful offline/permission failure messages. Do not present generated content as a translation guarantee or score.

## Files / Components

Backend provider/API/tests; mobile speech adapter, Help Me Say It controller/screen, router/Home and tests; native integration journey; docs and validation record.

## Data Model

No new persistent learner data. Current intention, expression, repetition and role-play response are transient. Backend stores none of them. A future phrase bank requires separate consent, retention and migration decisions.

## API Contract

`POST /v1/help-me-say-it` with pilot bearer and JSON `{"context_id":"beauty-cosmetology","intention":"..."}`. `200` returns `{"understood_meaning":"...","expression":"...","customer_cue":"..."}`. Inputs and outputs are bounded. Unknown context/invalid input is `400/422`, missing token `401`, unavailable provider `503`, provider failure/timeout `502/504`. No client-authored system instruction or level override.

## Privacy / Security

Voice and intended meaning may contain private learner details. Upload audio only for explicitly requested transcription, and intention text only after review. Do not log/store learner content; set provider `store: false`. Keep key server-only, use HTTPS outside debug localhost and safe errors. Pilot token remains internal-only; public access needs learner authentication and rate limits.

## Offline Behaviour

Learner can record and see already generated text while the screen stays open. New transcription or expression generation requires connectivity. A network failure preserves the current take and transcript for manual retry; no silent queue or background upload.

## Android / iOS Considerations

Use the same Flutter flow on both. Respect microphone permission, interruptions, lifecycle and audio routes. Test small screens, text scaling and device speech fallback. Run Android/iOS debug builds and available simulator native journey; physical-device checks wait for connected devices.

## Milestones

1. Implement the bounded provider/API contract with tests.
2. Build the three-stage mobile micro-lesson and failure recovery.
3. Add meaningful widget/client and native contract tests.
4. Run quality gate and update docs/decisions.

## Acceptance Criteria

- A learner can record an intention, review recognized words and explicitly ask for one usable expression.
- They can hear the expression, record a repetition, hear a customer cue and record one role-play reply.
- Offline/provider failure leaves the current work available for retry.
- UI never claims a translation certainty, pronunciation score or mastery result.
- Provider output is structurally validated and no secret or learner content is persisted in the mobile build/backend.
- Backend/Flutter tests and Android/iOS debug builds pass.

## Validation

```sh
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

- Intention inference may be wrong, especially with inaccurate transcripts. The learner must be able to inspect words and start again.
- Strict JSON controls shape, not semantic correctness or cultural fit. Educator review with consented learners is required.
- There is no live provider key or connected physical device in this environment.

## Decision Log

- 2026-10-02: Keep the micro-lesson short and explicit. Do not persist a phrase bank or infer a score from text-only recognition.
- 2026-10-02: Reuse the dialogue recorder because it already has separate ownership from the Day-1 lesson take. Clear temporary expression state on exit; retain a take after provider failure for manual retry.
- 2026-10-02: Keep the generated expression, meaning confirmation and customer cue in three bounded fields. Show a possible interpretation rather than asserting a certain translation.

## Progress

- [x] Read blueprint and Kora skill Help Me Say It pipeline.
- [x] Backend expression contract and tests.
- [x] Mobile intention, repeat and role-play stages with recovery.
- [x] Flutter/backend checks, Android build and iOS native simulator journey.
- [x] Generic iOS simulator debug build passed in GitHub Actions for `534d097`; local native simulator journey passed. The local generic build stalled and was interrupted after eight minutes, without a compiler error.
- [ ] Live provider and physical-device review before a learner pilot.
