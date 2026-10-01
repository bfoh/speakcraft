# Sprint 2 speech validation

Checked 2026-10-01. See the [ExecPlan](../.agent/plans/sprint-02-speech-recognition.md) for acceptance criteria and exact commands.

## Verified

| Check | Result | Evidence |
| --- | --- | --- |
| Backend formatting, lint and strict types | PASS | Ruff format/check and mypy on the backend. |
| Backend contract and provider-adapter tests | PASS | 15 pytest tests: authorization, disabled configuration, bounded `.m4a`, safe provider errors/timeouts, empty transcript, environment secrets and documented provider request shape. |
| Flutter formatting, analysis and unit/widget tests | PASS | 31 tests after the final audio-result control and native HTTP smoke were added. |
| Android debug build | PASS | `flutter build apk --debug` after adding HTTP upload and network permission. |
| iOS simulator build | PASS | `flutter build ios --simulator --debug` with Xcode 16.3. |
| Native iOS journey with local test HTTP server | PASS | `flutter test integration_test/foundation_test.dart -d BB727569-6977-4D3D-92E4-859BE36760BA`. Real SQLite and microphone capture, explicit multipart upload to an in-process test server, transcript display, deletion and saved phrase position. |

The backend API uses a test double in automated tests; the native HTTP smoke uses a local test server. Neither substitutes for a paid provider call. `OPENAI_API_KEY` is not set in this environment, so a live OpenAI transcription has not been verified. Do not record a recognition-accuracy claim until consented Ghanaian-accented samples have been compared with human transcripts.

**Quality status: BLOCKED for live speech recognition acceptance.** Source checks and both platform builds pass. The blocker is the missing server-side OpenAI key; no live provider call or target-accent accuracy check can be completed without credentials and consented speech samples. This is documented so independent implementation can continue without treating mocked recognition as production proof.

## Pilot prerequisites

- Connect Android and iOS devices and repeat microphone/network interruption, permission, Bluetooth/wired audio, screen-reader and large-text checks.
- Supply a server-only OpenAI key and review the account's data-retention settings before real learner audio is uploaded.
- Keep the pilot endpoint internal; add per-learner authentication and abuse controls before public exposure.
- Use HTTPS for physical-device access. The pilot access code is entered at runtime, is held only in app memory, and must not be compiled into the app.

## Known dependency warnings

`flutter_tts` currently builds but warns about future Kotlin Gradle Plugin and iOS Swift Package Manager compatibility. FastAPI's installed TestClient emits a Starlette/httpx deprecation warning; tests pass.
