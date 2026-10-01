# SpeakCraft Alpha architecture

## Foundation and boundaries

A Flutter application runs the beginning of Day 1 on Android and iOS. A separate FastAPI process exposes liveness and optional speech transcription. The mobile application remains usable offline and does not require the backend for navigation or recording. There is no learner authentication, cloud database, generated conversation, evaluation, or synchronisation in this build.

The architecture follows blueprint sections 18–20. The explicit Sprint 1 instruction limits the full AI vertical slice proposed in section 35; see DECISIONS.md.

## Sprint 2 speech slice

An explicit Day-1 action sends the current `.m4a` recording to SpeakCraft's `POST /v1/speech/transcribe`. Flutter knows only the SpeakCraft API contract. Its URL is a nonsecret build configuration; a facilitator enters an internal pilot access code at runtime, retained in memory only. The mobile client rejects insecure remote HTTP URLs. Speech recognition is unavailable when no server URL is configured, while local recording still works.

FastAPI requires a pilot bearer token and a server-only OpenAI key before accepting an upload. It reads at most 4 MiB, checks the `.m4a` container signature, forwards bytes through a `Transcriber` interface to OpenAI's documented file transcription endpoint, and returns transcript text. Audio and text are not stored on the server. An empty transcript is shown as no words recognised; no score or correction is inferred. Provider errors and timeouts return safe responses, and the app keeps the local take for manual retry.

This pilot access mechanism is limited to local/internal testing. Public deployment needs per-learner authentication, rate limits, and a reviewed retention policy. No live provider call was possible during implementation without an API key.

## Mobile structure

- `lib/app`: composition, Riverpod providers, GoRouter routes and theme.
- `lib/core/curriculum`: immutable typed models and bundled curriculum validation.
- `lib/core/storage`: progress repository interface and native SQLite adapter.
- `lib/core/audio`: microphone interface, native recording adapter, authored-text speech output.
- `lib/features/onboarding`: welcome, profession, support language, Kora introduction, assessment introduction.
- `lib/features/home`: Day-1 entry and a preview of the five-day journey.
- `lib/features/lesson`: phrase practice, microphone state controller and UI.
- `lib/shared`: responsive page, buttons, cards, notices and listen control.

Riverpod supplies application dependencies. The bootstrap loads native services, then passes them through a scoped provider. Providers that depend on those services explicitly declare their scoped dependencies, including the router. Small ChangeNotifier controllers expose synchronous UI state around asynchronous operations. GoRouter guards routes until onboarding is saved. The router is disposed with its provider. Native adapters are isolated from widgets and can be replaced by explicit test doubles in tests.

## Local state

SQLite schema version 1 creates one `learner_progress` row. It stores onboarding step, profession, support language and Day-1 phrase index. The repository uses parameterised queries. Changes become visible only after a successful database write; write failure preserves the previous state and exposes retry. This is navigation progress, not evidence of mastery or lesson completion.

Future local changes must increment the schema version and provide tested upgrades. No remote database schema or credentials are introduced. Routine audio is separate cache data, excluded from learning history.

## Curriculum

`curriculum/alpha.json` is the editorial source of truth for the five Alpha days. `scripts/sync_curriculum.py` validates it and copies identical content into `mobile/assets/curriculum/alpha.json`. CI checks that copy for drift. No symlinks outside the Flutter project are required for packaging.

Day 1 has four authored prompts, ending in the blueprint's 30–60 second introduction. Days 2–5 contain objectives, target language and initial prompts; their activities remain unavailable. Example sentences are editorial seeds requiring educator review. They are not generated assessment data.

## Voice boundary

`Microphone` provides permission, start, stop, discard, interruption and disposal operations. `NativeMicrophone` implements it through `record`, storing mono AAC in a private cache directory. `MicrophoneController` owns visible transitions and a 60-second limit. UI requires separate permission and start actions. Navigation or backgrounding ends active capture. A take stays available during in-app navigation until replaced/discarded; cache cleanup occurs on the next app launch.

The microphone processing state only represents local audio work. Recording success means a nonempty file exists; it does not mean a learner was understood. A separate, explicit upload action may return a transcript through the SpeakCraft backend. No score is computed or shown.

`flutter_tts` reads authored instructions/examples through the device speech engine. It does not send learner audio to an AI service. English voice availability depends on device settings, and offline voice availability varies. The UI offers text and a useful failure message. Reference speech does not establish an accent standard.

## Backend

`backend/app/main.py` defines an application factory, a typed `GET /health` endpoint and the bounded, pilot-protected `POST /v1/speech/transcribe`. The factory accepts settings and a test transcriber. Configuration comes from `SPEAKCRAFT_` variables plus a server-only `OPENAI_API_KEY`. Interactive docs and OpenAPI are disabled by default and opt in via `SPEAKCRAFT_DOCS_ENABLED=true`. No broad CORS policy or speculative learner-data routes are installed.

Use an authenticated SpeakCraft API boundary for future learner data. Provider credentials must remain server-side. Do not add a cloud service merely to serve current local content.

## Dependencies

Runtime mobile dependencies each have a specific role: Riverpod (composition), GoRouter (navigation), sqflite (durable local state), record (native capture), path_provider (private storage locations), flutter_tts (audio instructions) and http (SpeakCraft API transport). Tests additionally use sqflite_common_ffi to test actual SQLite reopen behavior on a host.

FastAPI provides routing and schemas, Uvicorn serves ASGI, pydantic-settings reads typed configuration, python-multipart parses the bounded upload, and httpx sends it to the provider. Dependency resolutions are tracked in `mobile/pubspec.lock` and `backend/requirements-dev.lock`. Flutter is pinned in `.flutter-version` and CI. Do not manually update generated native files without preserving both platform targets.

## Platform baseline

Flutter 3.47.5 / Dart 3.13.4. Android API 24+ with compile/target SDK 36; Java 17. iOS 15+. The iOS project has no team identifier in source; developers choose their own team for physical devices. Android release signing is not configured. These are development builds, not store submissions.

## Reference documentation

- [Flutter installation](https://docs.flutter.dev/install/manual)
- [Riverpod](https://pub.dev/packages/flutter_riverpod)
- [GoRouter](https://pub.dev/packages/go_router)
- [Native recording and permission setup](https://pub.dev/packages/record)
- [Device text to speech](https://pub.dev/packages/flutter_tts)
- [SQLite](https://pub.dev/packages/sqflite)
- [FastAPI testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [OpenAI file transcription](https://developers.openai.com/api/docs/guides/speech-to-text)
