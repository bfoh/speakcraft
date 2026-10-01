# Sprint 2 — Hear the learner

## Goal

Let a learner make a Day-1 recording, explicitly send that take for speech recognition, read what the system heard, and retry. This is the next small vertical slice toward the five-day Alpha; later teaching and conversation milestones remain separate.

## Context

Sprint 1 provides native recording, a local Day-1 lesson, SQLite navigation progress, a Flutter Android/iOS shell, and a FastAPI health service. The Product & Technical Blueprint sections 20, 26–28 and 31 call for recorded-speech transcription as Build 0.2. `AGENTS.md` requires provider-specific code on the backend and no mobile provider key. Official OpenAI documentation for [file transcription](https://developers.openai.com/api/docs/guides/speech-to-text) was consulted through the configured OpenAI developer documentation MCP before implementation.

## Non-goals

No speaking score, pronunciation judgement, correction, AI Salon, Help Me Say It, live conversation, automatic background upload, or claimed learning improvement. No public backend deployment or learner account system. Do not silently substitute a fake transcript if the provider is unavailable.

## User Journey

After recording on Day 1, the learner can continue practising offline or choose **Hear my words**. The app explains that this sends the current recording for speech recognition. A successful response displays the transcript as a tentative reading of the speech and offers another attempt. A failed connection or unavailable service leaves the take on the phone, explains the problem simply, and offers a manual retry. New takes, phrase changes and deletion clear stale transcripts.

## Technical Approach

- Add `POST /v1/speech/transcribe` to FastAPI using a bounded multipart `.m4a` upload and typed JSON response. Reject missing/invalid/oversized media before calling the provider. Keep content and filenames out of logs and responses.
- Use a small backend `Transcriber` interface and an OpenAI adapter. The adapter sends completed audio to the documented `/v1/audio/transcriptions` endpoint with `gpt-transcribe`, validates a nonempty `text` field, and maps timeouts/provider failures to safe errors. The OpenAI key stays in backend environment variables.
- Keep the endpoint unavailable until both a backend provider key and a pilot access token are configured. Compare bearer tokens safely. The pilot token is entered by a facilitator at runtime in the app and held only in memory; it is never compiled into the mobile binary or committed. Do not expose this pilot service publicly without a proper account/auth and abuse-control design.
- Add a provider-neutral Flutter speech-recognition interface and HTTP adapter. Configure only a nonsecret backend URL with `--dart-define`. Keep the upload behind an explicit learner action and surface sending, result, offline, authorization and server-failure states. Never infer a score from a transcript.
- Preserve existing local recording and navigation when requests fail. No automatic retry or queue of sensitive audio. A new request is always a learner action.

## Files / Components

`backend/app/config.py`, `main.py`, new speech/provider module and tests; backend dependency lock and `.env.example`; `mobile/lib/core/speech`, Day-1 UI/controller, app services and tests; Android/iOS development network settings; README, architecture, privacy and decision records.

## Data Model

No new persistent data. The current `.m4a` remains in the private app cache during the session. A transcript is in memory only and cleared with its recording. The backend processes bytes in memory for one request and stores neither audio nor transcript. The provider receives the uploaded audio for transcription; its retention is governed by the provider account settings and policy, which must be reviewed before a learner pilot.

## API Contract

`POST /v1/speech/transcribe`, multipart form with `audio` (AAC in `.m4a`), `Authorization: Bearer <pilot-token>`. `200 {"transcript":"..."}`; an empty transcript means no words were recognised. `400` malformed/empty media; `401` missing/wrong access token; `413` oversized audio; `503` speech not configured; `502/504` provider failure/timeout. The backend does not receive a prompt ID because transcription does not need it. Never return provider internals. `/health` remains liveness only.

## Privacy / Security

The learner explicitly starts capture and explicitly chooses upload. A short notice states that audio goes to the SpeakCraft server for speech recognition. The backend validates bearer access, file size/type and prompt ID, applies a provider timeout and returns only transcript text. No provider key or privileged token enters mobile source. The pilot token is session-memory only. Backend must not persist or log audio/transcripts. Public launch needs proper learner identity, per-user authorization, rate limits, secure transport, and a retention review.

## Offline Behaviour

Recording, listening to authored examples, local phrase progress and navigation remain offline. **Hear my words** requires a backend connection. Connection failure retains the take and shows a retry action; no hidden upload occurs when connectivity returns. A process restart still removes routine audio, as in Sprint 1, and this limitation must remain visible in documentation.

## Android / iOS Considerations

The same Dart client runs on both. Android debug builds may reach a local HTTP development server; release builds require HTTPS. iOS simulator can reach local development services with an explicit local-network exception; production should use HTTPS. Neither platform automatically uploads on lifecycle changes. Existing microphone interruption handling remains. Device permission, connectivity, wired/Bluetooth audio and large-text checks await connected hardware.

## Milestones

1. Plan and verify current provider documentation and toolchain.
2. Implement the secure, bounded backend contract and isolated provider adapter with tests.
3. Add Flutter client, explicit upload/result/retry UI and tests without regressing offline practice.
4. Run formatting, analysis, tests, Android/iOS builds and an integration smoke where the environment permits. Update docs and quality findings.

## Acceptance Criteria

- A valid authorized `.m4a` returns a provider transcript without a fake score.
- Missing/wrong access token, bad/large media, unavailable configuration, provider failure and timeout produce distinct safe API responses.
- The Day-1 learner chooses when to upload, sees a transcript on success, and can rerecord or retry upload.
- A failed/offline request preserves the recording and saved phrase position.
- Replacing or deleting a take removes its old transcript.
- Both platform builds, formatting, static checks and relevant automated tests pass, or exact blockers are documented.

## Validation

From the repository root:

```sh
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

Exercise the live provider only when a non-committed `OPENAI_API_KEY` and pilot token are available. Do not claim a live transcription was verified from mocked tests. Repeat the native journey on Android and iOS devices when the user connects them.

## Risks / Unknowns

- No OpenAI key is present in the current environment, so a paid live transcription cannot yet be verified.
- Ghanaian-accented English transcription accuracy needs a consented, human-reviewed sample; one model response does not establish reliability.
- A facilitator-entered pilot token is suitable only for local/internal Alpha testing. Public exposure needs account authentication and abuse controls.
- Local HTTP behavior and real connectivity changes must be tested on connected Android and iOS hardware.

## Decision Log

- 2026-10-01: Follow blueprint Sprint 2 before teaching feedback; a transcript is evidence of what recognition returned, not evidence of communication success.
- 2026-10-01: Use completed-file transcription with `gpt-transcribe` per current official docs, behind a backend interface. Keep the recording and retry decision under learner control.
- 2026-10-01: Require a 32-character minimum pilot token and reject unauthorised or oversized requests before parsing multipart content. Keep the pilot code in app memory only, entered by a facilitator.
- 2026-10-01: A native iOS simulator journey validates real capture and multipart HTTP transport with a local test server. It does not establish OpenAI transcription quality.

## Progress

- [x] Read guidance, blueprint and current implementation; consult OpenAI developer documentation MCP.
- [x] Backend API and provider adapter with contract tests.
- [x] Flutter client and learner journey with unit/widget and native iOS transport tests.
- [~] Quality gate and documentation: source checks and Android/iOS builds pass; live provider verification awaits a server-only key and consented target-accent samples. See `docs/SPRINT_2_VALIDATION.md`.
