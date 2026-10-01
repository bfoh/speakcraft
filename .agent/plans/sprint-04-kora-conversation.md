# Sprint 4 — Bounded Day-1 Kora conversation

## Goal

Let a learner apply their Day-1 introduction in a short spoken exchange with Kora. Kora should ask a relevant follow-up in simple English, listen to a recorded answer, and respond within the Day-1 objective.

## Context

The existing lesson supports native recording, explicit transcription, prompt-bound feedback and device speech. The blueprint's core loop ends with Apply; Sprint 4 calls for natural Kora voice interaction. This slice adds a bounded three-turn Day-1 dialogue using the existing completed-file voice pipeline. It does not claim streaming latency.

## Non-goals

No Realtime streaming, open-ended chatbot, scenario role-play, AI Salon, assessment score, mastery badge, remote session storage, adaptive memory or additional language support. Those need their own plans and validation.

## User Journey

After Day-1 practice, the learner opens **Talk with Kora**. Kora speaks an authored opening. The learner records, explicitly asks to see their words, checks the tentative transcript, and explicitly sends that text as a reply. Kora gives a short response and one relevant question. The learner can listen and answer again, up to three turns. Network failure keeps the take, transcript and earlier dialogue available for retry. Leaving clears the in-memory dialogue.

## Technical Approach

- Store the opening, objective and turn limit as reviewed curriculum data, packaged identically for mobile and backend.
- Add `POST /v1/kora/respond` behind the internal pilot bearer guard. The request carries a Day-1 lesson ID, bounded recent turn history and a bounded current transcript. Backend resolves the authored conversation goal itself. It forwards untrusted transcript/history as data to a provider-neutral conversation adapter using Responses structured output with storage disabled. Validate response length and shape; never expose provider text on failure.
- Add a Flutter conversation HTTP client and controller. Reuse the existing microphone and transcription abstractions, keeping user-initiated recording/upload/reply as separate actions. Device speech reads authored and generated Kora text. Keep the pilot code in memory and transcript/take on failure.
- Use responsive reusable components and explicit recording, sending, offline and recovery states. Limit dialogue to three learner turns.

## Files / Components

Canonical curriculum and sync/validation script; `backend/app` conversation adapter, request schema and route; backend tests; `mobile/lib/core/speech`, `mobile/lib/features/conversation`, router/Home/lesson entry, tests and native integration; docs and validation record.

## Data Model

No persistent learner data. The current dialogue and generated replies live in mobile memory and disappear when leaving the flow. Backend is stateless and stores neither transcript nor dialogue. Curriculum data is versioned editorial content.

## API Contract

`POST /v1/kora/respond` uses `Authorization: Bearer <pilot-token>` and JSON `{"lesson_id":"day-1","turns":[{"speaker":"kora","text":"..."},...],"transcript":"..."}`. `200` returns `{"reply":"...","next_question":"..."}` where the next question may be null on the final turn. Invalid/oversized input is rejected before provider use; missing/invalid token is `401`, unconfigured service `503`, provider failure/timeout `502/504`. Backend does not accept a client-authored lesson goal.

## Privacy / Security

Speech and dialogue are sensitive. No recording, transcript, history or generated reply is persisted server-side or logged. Send to OpenAI only on learner action, use `store: false`, and keep the provider key server-only. Treat all client-provided turns as untrusted and validate roles, count and lengths. HTTPS is required outside debug localhost. This shared pilot token is internal-only; public access needs learner auth, rate limits and retention review.

## Offline Behaviour

The authored opening and existing dialogue remain readable, and recording remains local. Transcription and Kora replies require connectivity. A failed request leaves the take and transcript for explicit retry. Nothing syncs silently.

## Android / iOS Considerations

The same Flutter screen and client run on both. Reuse tested permission, interruption, audio-route and cache behavior. The separate dialogue screen must stop capture on background/navigation. Run unit/widget tests, Android/iOS debug builds and available simulator native journey. Physical-device checks wait until the user connects devices.

## Milestones

1. Author and validate a bounded Day-1 conversation in canonical curriculum data.
2. Build the authenticated, stateless conversation API and provider tests.
3. Build the voice-first learner dialogue with explicit actions and failure recovery.
4. Run quality checks and native builds; document limitations and decisions.

## Acceptance Criteria

- Learner can hear Kora's authored opening, record an answer, review transcript and explicitly send a reply.
- Kora remains inside Day-1 introduction and asks a simple relevant follow-up; maximum three learner turns.
- Bad transcript, bad history, unauthorized request and provider failures never produce a fake Kora reply.
- Leaving or starting over clears transient dialogue; network failure preserves current take/transcript while on screen.
- No keys are bundled in mobile or private content stored on backend.
- Backend/Flutter tests, Android/iOS debug builds and available native simulator checks pass.

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

- Completed-file exchange has more latency than a streaming voice conversation; actual learner timing requires device evaluation.
- Strict JSON validates shape, not conversational relevance or safety. Educator review with consented learners is still required.
- There is no live provider key in this environment, so provider output quality cannot be verified here.

## Decision Log

- 2026-10-01: Use a bounded, stateless, explicit-turn exchange before a lower-latency architecture. Reuse the existing speech and device TTS boundaries and do not store a conversation on the server.
- 2026-10-02: Give lesson and conversation independent native recorders/cache folders. The initial shared recorder would have discarded a saved lesson take on entering conversation. The native simulator test now checks take preservation.
- 2026-10-02: Allow a prior Kora turn of up to 400 characters because a valid 180-character reply and 180-character question can be combined in the client's turn history.
- 2026-10-02: Treat the API history as untrusted, bounded context. The backend is stateless; the mobile controller limits each exchange to three learner turns.

## Progress

- [x] Read blueprint/Kora guidance and inspect current speech, lesson and routing code.
- [x] Curriculum and authenticated, bounded backend with structured provider output.
- [x] Flutter conversation journey with separate native recorder, explicit actions and recovery.
- [x] Source checks, Android/iOS debug builds, iOS native contract test and documentation.
- [~] Live-provider/educator validation and physical-device checks remain pending until a key, consented samples and connected devices are available.
