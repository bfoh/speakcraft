# Sprint 3 — First Kora teaching response

## Goal

After a Day-1 transcript, give one short, useful piece of feedback about communication and invite another attempt. This advances the five-day Alpha through a complete hear → speak → understand → correct → retry loop without claiming a pronunciation score from text.

## Context

Sprint 2 added an explicit Day-1 upload and a provider-neutral transcript contract. The blueprint sections 4–8, 20–22 and 31 and `docs/KORA_PEDAGOGY.md` govern the teaching behavior. The SpeakCraft Kora skill prioritises meaning and task completion and normally corrects one high-value issue. Current official OpenAI [Structured Outputs guidance](https://developers.openai.com/api/docs/guides/structured-outputs) was consulted through the configured OpenAI developer documentation MCP before this plan.

## Non-goals

No pronunciation scoring from transcripts, numerical performance score, baseline assessment result, general chatbot, live conversation, AI Salon, Help Me Say It, adaptive memory or remote learner profile. Do not expand Days 2–5 until the Day-1 feedback loop is coherent.

## User Journey

The learner records and explicitly uploads a take. The transcript appears as a tentative reading. If it looks wrong, the learner records again. If it looks right, they choose **Help me say it better**. Kora responds briefly: acknowledge what was understood, point to at most one important improvement, show a level-appropriate example when useful, and invite another attempt. The learner may listen to the feedback and retry recording. A failure leaves the transcript and take available.

## Technical Approach

- Package the canonical human-authored curriculum into the backend as well as Flutter. The backend looks up `lesson_id` and `prompt_id` itself, so the client cannot redefine objectives.
- Add `POST /v1/speech/evaluate` behind the same internal pilot bearer guard. Validate IDs and a bounded transcript. Build the model request from authoritative objective, instruction, target language and learner transcript. Mark learner speech as untrusted data and direct the model to stay in the teaching role.
- Use OpenAI Responses structured output behind a `FeedbackProvider` interface. Validate the returned JSON again with Pydantic and reject malformed, missing, excessive or unsafe fields. Expose only a small learner-facing contract with an outcome, short feedback and optional example. Do not accept provider-generated scores or pronunciation claims.
- Add a provider-neutral Flutter feedback client and controller. Share the runtime pilot code without writing it to disk. Preserve transcript and recording across feedback failures; clear stale feedback when the take changes. Read returned feedback through the existing device speech control.
- Keep model choice and credential server-side. The pilot remains internal until real learner evaluation, authentication and abuse controls are in place.

## Files / Components

`curriculum/alpha.json`, packaging script and backend packaged asset; `backend/app` curriculum, feedback provider, config and API; backend tests; `mobile/lib/core/speech`, Day-1 controllers/UI and tests; README, pedagogy, architecture, privacy, decision and validation records.

## Data Model

No new persistent learner data. The feedback response is in app memory with the transcript and recording. The backend stores no transcript or feedback. Curriculum assets are versioned project data, not learner records. Later learning-memory storage requires a separate migration and consent/design review.

## API Contract

`POST /v1/speech/evaluate` with JSON `{"lesson_id":"day-1","prompt_id":"introduce-name","transcript":"..."}` and `Authorization: Bearer <pilot-token>`. `200` returns `{"outcome":"clear|improve|retry","feedback":"...","example":"...|null"}`. `400/422` invalid or unknown input, `401` missing/wrong token, `503` unconfigured service, `502/504` provider failure/timeout. Provider internals, prompt text and scores are never returned. The endpoint must not accept a client-authored objective.

## Privacy / Security

Transcript text is sensitive learner content and is sent to the provider only after the learner chooses feedback. No transcript or feedback is logged or persisted server-side. Limit request/response sizes. A prompt-injection attempt inside a transcript is treated as speech content, not an instruction. Auth and HTTPS requirements follow Sprint 2. Provider retention settings require review before real learner use. Public deployment needs per-learner authentication and rate limits.

## Offline Behaviour

Recording, existing transcript display, authored examples and local navigation work offline. Feedback generation requires the backend. Connection failure keeps the take and transcript and offers manual retry; no background upload or silent feedback generation.

## Android / iOS Considerations

Use the same Flutter widgets/API client on both. Feedback text remains readable on small screens and large text settings. The listen control uses installed device voices and has a visible text alternative. Microphone permission and interruption behavior remain unchanged. Build and run relevant tests for both targets; connected-device audio/accessibility checks remain deferred until hardware is supplied.

## Milestones

1. Package and validate the canonical curriculum for backend lookup.
2. Implement the authenticated structured-feedback API and provider adapter with tests for safety and error paths.
3. Add the Day-1 feedback action, short result/audio, retry and stale-result handling with Flutter tests.
4. Run formatting, static checks, tests and native builds; update docs and record live-provider/device limitations.

## Acceptance Criteria

- Backend rejects unknown lesson/prompt and oversized/empty transcripts without a provider call.
- Feedback schema never contains a fabricated numerical or pronunciation score.
- An authorized, valid provider response yields a short outcome, feedback and optional example tied to the current prompt.
- Malformed/refused/provider-failed responses become safe errors, not learner-facing raw content.
- The learner requests feedback explicitly after a transcript and can hear it, rerecord, or retry after network failure.
- Replacing/deleting a take clears the old transcript and feedback.
- Flutter and backend checks and Android/iOS debug builds pass, with live-provider validation reported separately.

## Validation

From repository root:

```sh
python3 scripts/sync_curriculum.py --check
backend/.venv/bin/ruff format --check backend scripts
backend/.venv/bin/ruff check backend scripts
backend/.venv/bin/mypy --config-file backend/pyproject.toml backend/app
backend/.venv/bin/pytest -c backend/pyproject.toml backend/tests
cd mobile
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Run a live provider/human-review evaluation only after the backend has a non-committed key and consented target-learner speech. Mocked responses establish contract and UI behavior, not pedagogy quality.

## Risks / Unknowns

- There is no provider key or consented Ghanaian-accented sample in this environment, so live teaching quality cannot yet be established.
- Transcription errors can lead to unfair feedback; the learner must be able to rerecord instead of accepting a bad transcript.
- Strict schema controls format, but it does not prove that advice is accurate, kind or limited to one useful correction. Representative human review is required.
- A facilitator-entered pilot code and shared endpoint remain internal-only mechanisms.

## Decision Log

- 2026-10-01: Keep teaching feedback separate from transcription so the learner can see what was heard and choose whether to ask for help.
- 2026-10-01: Use the backend's packaged human curriculum as authority and structured model output validated again by application code. Exclude pronunciation and numerical scores from the text-only contract.
- 2026-10-01: Set `store: false` on the Responses request, following the current OpenAI API contract. Keep generated feedback in memory only and separate the learner's transcription action from feedback generation.
- 2026-10-01: The native iOS simulator test requires its microphone grant after installation. A permission prompt blocked the first rerun; granting the installed app and rerunning passed. The test uses a local server for transport, not live provider output.

## Progress

- [x] Read product/Kora guidance and current implementation; consult OpenAI developer documentation MCP.
- [x] Backend curriculum packaging and feedback API.
- [x] Flutter learner experience and voice controls.
- [x] Source checks, Android/iOS debug builds, iOS native contract test and documentation.
- [~] Live provider and educator validation blocked until a server key and consented learner samples are available; physical-device checks wait for connected devices.
