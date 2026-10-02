# SpeakCraft Alpha architecture

## Foundation and boundaries

A Flutter application runs guided practice across five days on Android and iOS. A separate FastAPI process exposes liveness, optional speech transcription, prompt-bound teaching feedback, a bounded Kora dialogue, Help Me Say It and three structured AI Salon scenarios. The mobile application remains usable offline and does not require the backend for navigation or recording. There is no learner authentication, cloud database, scored assessment or synchronisation in this build.

The architecture follows blueprint sections 18–20. Later slices remain bounded to the authored Alpha pathway; see DECISIONS.md.

## Sprint 2 speech slice

An explicit Day-1 action sends the current `.m4a` recording to SpeakCraft's `POST /v1/speech/transcribe`. Flutter knows only the SpeakCraft API contract. Its URL is a nonsecret build configuration; a facilitator enters an internal pilot access code at runtime, retained in memory only. The mobile client rejects insecure remote HTTP URLs. Speech recognition is unavailable when no server URL is configured, while local recording still works.

FastAPI requires a pilot bearer token and a server-only OpenAI key before accepting an upload. It reads at most 4 MiB, checks the `.m4a` container signature, forwards bytes through a `Transcriber` interface to OpenAI's documented file transcription endpoint, and returns transcript text. Audio and text are not stored on the server. An empty transcript is shown as no words recognised; no score or correction is inferred. Provider errors and timeouts return safe responses, and the app keeps the local take for manual retry.

This pilot access mechanism is limited to local/internal testing. Public deployment needs per-learner authentication, rate limits, and a reviewed retention policy. No live provider call was possible during implementation without an API key.

## Sprint 3 teaching slice

The learner sees the tentative transcript before separately requesting **Help me say it better**. Flutter sends `lesson_id`, `prompt_id` and transcript to `POST /v1/speech/evaluate`; it does not send an editable lesson objective. FastAPI resolves the prompt against a packaged, byte-identical copy of `curriculum/alpha.json`. Requests and returned fields are bounded. Kora's provider adapter uses OpenAI Responses with a strict JSON schema and `store: false`; Pydantic validates the result again. Only a short outcome, feedback and optional example reach the app. The server does not retain them.

The model receives text, not audio. It is instructed to prioritize meaning and task completion, offer at most one useful improvement and avoid pronunciation judgements, scores and invented personal facts. Schema validation controls shape, while educator review remains necessary to establish teaching quality. Feedback failures preserve the take and transcript for manual retry. The mobile controller invalidates stale feedback after a changed take or prompt.

## Sprint 4 conversation slice

The authored Day-1 conversation opening, goal, turn limit and success conditions live in canonical curriculum data and are copied to both runtimes. A learner records an answer, explicitly requests transcription and then explicitly sends the reviewed text to `POST /v1/kora/respond`. The request includes up to five prior dialogue turns. FastAPI validates the sequence and resolves the authoritative goal; it does not hold a server session. The provider uses Responses structured output with `store: false` to return a short reply and optional follow-up question. The client limits the exchange to three learner turns. Dialogue stays in mobile memory only, and failures retain the current answer for manual retry. This completed-file mode is not a low-latency Realtime implementation.

Lesson practice and Kora dialogue use separate native recorders and private cache folders. Starting or leaving a conversation cannot discard a lesson practice take. Both folders are cleaned on the next app launch.

## Sprint 5 AI Salon slice

`curriculum/alpha.json` also contains the first difficulty-1 scenario: a friendly customer wants braids and asks about price. It specifies the scenario and customer goals, personality, learner objectives, target language, success conditions, opening and a four-turn limit. The same dialogue screen uses customer-facing text and maps its partner turns to `customer` at the `POST /v1/salon/respond` boundary. The backend validates the authored scenario and alternating history, then requests a short, structured customer reply from the provider with `store: false`. The provider is instructed not to invent a real salon price, booking or assessment result. The app does not claim successful completion or persist the exchange. The stateless endpoint is used until a genuine session/assessment store is needed.

## Sprint 6 Help Me Say It slice

The learner records an intention, reviews the tentative transcript and explicitly sends it to `POST /v1/help-me-say-it`. The authenticated backend accepts only the authored Beauty & Cosmetology context identifier and a bounded intention. Responses structured output returns a brief meaning confirmation, one expression and one customer cue; Pydantic validates all fields and provider storage is disabled. The mobile controller advances through intention, repeat and short role-play only after learner actions. The expression and subsequent transcripts remain in memory. Dialogue uses the separate conversation recorder, so Day-1 practice takes remain untouched. Recognition transcripts document what was heard; they do not establish pronunciation quality.

## Sprint 7 daily practice slice

The same lesson screen now reads any of the five validated curriculum days. Days 2–5 contain short authored sequences that teach the blueprint vocabulary and conversation moves. The `POST /v1/speech/evaluate` contract already resolves any authored lesson/prompt pair. Home opens each day and states that longer consultations and the final challenge are not assessed by these pages. Switching to another prompt or day clears the prior take before it can be shown or uploaded under the new prompt.

## Sprint 8 salon progression slice

The canonical curriculum now contains three structured scenarios: first braids-and-price practice, a Day-3 needs consultation and a Day-5 extended customer exchange. Each has authored goals, personality, opening, objectives, target language, success conditions and turn limit. The backend checks the selected ID and exact opening, alternating roles, per-turn lengths and the scenario's limit before calling the provider. Its developer instruction is scenario-neutral; the selected scenario data is authoritative. The same Flutter dialogue UI is parameterised by scenario ID and linked from the relevant daily lesson. No conversation is stored or scored, and reaching the turn limit is practice completion rather than a validated challenge result.

## Sprint 9 practice and privacy slice

A dedicated Progress screen reads the five prompt positions from `SessionController` and opens each day. It labels these as saved places, not assessment. A Privacy screen explains local storage and explicit network actions. Confirmed reset stops and discards current recorder takes, clears transient transcript/feedback/dialogue and the in-memory pilot code, then deletes local progress in one SQLite transaction. The session publishes default onboarding only after durable deletion. Cleanup and SQLite deletion remain separate operations, so any failure reports retry without claiming complete erasure. The reset works offline and makes no backend request.

## Sprint 10 offline review slice

Ten stable, authored review items live in canonical curriculum data and are packaged into the mobile and backend assets. `ReviewController` shows due phrases, plays them through the existing device speech output, and saves only an explicit self-rating. The deterministic scheduler returns a phrase in four hours after **More practice**, or after one, three or seven days across repeated **Felt easy** choices. These intervals are a starting rule, not a validated mastery model. SQLite schema version 3 adds `review_state` without losing older progress; confirmed local reset deletes that table in the same transaction. No review endpoint, transcript or audio history is added.

## Sprint 11 slower replay slice

The shared `SpeechOutput` contract accepts an optional slow flag. `DeviceSpeechOutput` maps it to a gentler device TTS rate and retains the existing English voice preference. A phrase's shared audio component coordinates its normal and slow controls, so only one can be active in that component. This adds no persistence, network request or pronunciation judgement; the native voice and audio route vary by device.

## Sprint 12 unscored baseline capture slice

Seven validated `baseline_items` (authored in curriculum version 0.1.1) cover the blueprint's five Day-1 parts. The role-play uses three authored customer lines; this flow makes no provider call. A generated salon visual is packaged with the app and labelled as provisional. A dedicated native microphone keeps assessment takes apart from lessons and dialogue. `NativeAssessmentCaptureStore` stages each accepted take in app-private temporary storage, copying to a pending file before rename. `AssessmentController` advances only after staging succeeds. The controller holds the current position and capture paths in memory, so navigation within the app preserves them, while app relaunch deletes old assessment audio. Privacy reset clears both assessment folders before SQLite reset. There is no assessment endpoint, result, score, transcript or durable comparison data.

## Sprint 13 guided-practice completion slice

SQLite schema version 4 adds `practice_attempts`, a set of authored prompt IDs for which a nonempty native take was saved and the learner explicitly advanced or saved the last step. The attempt marker and current position are written in one transaction. All current prompt IDs must be present before a day displays `Practice steps finished`. Skipping remains possible but adds no marker. This is participation evidence only: it stores no audio, transcript or speaking result, and Days 3 and 5 do not claim completion of their longer challenges.

## Sprint 14 AI Salon rehearsal progress slice

SQLite schema version 5 adds `salon_rehearsals` with the most learner replies completed in one terminal Day-3 or Day-5 scenario. `ConversationScreen` writes only after a successful provider response ends the exchange; early provider endings save their actual shorter count. A failed local save retains the visible dialogue and offers retry. The final screen displays the scenario's authored learner objectives for self-review. The count is local participation evidence, not a duration, communication score or success judgement; no conversation text or audio is retained.

## Sprint 15 recorded-answer time slice

The conversation microphone uses a monotonic stopwatch from successful native start until stop is requested. Its duration excludes native stop processing, transcription and network wait, and is capped at the take limit. `ConversationController` adds a take's duration only after a successful provider response, so failed sends and retries cannot double-count it. SQLite schema version 6 stores each scenario's longest total recorded-answer seconds separately from its best completed-reply count. These maxima can come from different rehearsals. The measure may include silence and does not time the customer's turns or the whole consultation.

## Sprint 16 starting-answer playback slice

`RecordingPlayback` isolates local `.m4a` playback from widgets. The native adapter uses `audioplayers` to open an existing app-private file and releases its player on stop. `AssessmentPlaybackController` handles loading, playing, completion and failure. The starting-assessment screen can replay the current take and staged answers from `AssessmentController`'s in-memory paths. Playback stops before new capture, navigation, interruption or deletion. No recording survives the existing cache lifetime, and there is no schema or API change.

## Sprint 17 learner confidence slice

SQLite schema version 7 adds `confidence_check_ins` with the latest 1–5 learner-reported readiness and UTC time for `starting` and `day5`. The same optional question appears after all seven starting recordings and after all Day-5 guided speaking steps. `SessionController` confirms a choice only after the local transaction succeeds. My practice shows each self-rating separately, without a derived change or speaking score. Clear phone data deletes both rows. No audio, transcript or backend request is involved.

## Sprint 18 fixed Day-5 challenge slice

Curriculum version 0.1.2 adds five validated `day5_challenge_items`. After all Day-5 guided steps have saved attempt markers, a separate route reuses the assessment capture screen with its own microphone, playback controller and private temporary cache. It records the customer's need, greeting, question, recommendation with reason and closing through fixed lines. Route guarding prevents opening the challenge before guided practice is finished. Saves are staged before the prompt advances, and local clear/reset failures leave a retry path. The challenge makes no provider call and stores no SQLite completion or score. The recordings expire at next app launch, so it is not yet an English Mirror history.

## Mobile structure

- `lib/app`: composition, Riverpod providers, GoRouter routes and theme.
- `lib/core/curriculum`: immutable typed models and bundled curriculum validation.
- `lib/core/storage`: progress repository interface and native SQLite adapter.
- `lib/core/audio`: microphone and playback interfaces, native recording/playback adapters, authored-text speech output.
- `lib/core/speech`: backend-facing transcription and teaching-feedback contracts.
- `lib/features/onboarding`: welcome, profession, support language, Kora introduction, assessment introduction.
- `lib/features/assessment`: unscored starting and Day-5 fixed capture flows with separate private session storage.
- `lib/features/home`: five-day entry and practice positions.
- `lib/features/progress`: saved daily positions and resume navigation.
- `lib/features/review`: offline My Words listening and self-rated scheduling.
- `lib/features/settings`: local privacy explanation and confirmed phone-data reset.
- `lib/features/lesson`: phrase practice, microphone state controller and UI.
- `lib/features/conversation`: bounded Day-1 dialogue controller and screen.
- `lib/features/help_me_say_it`: short intention, repeat and customer role-play flow.
- `lib/shared`: responsive page, buttons, cards, notices and listen control.

Riverpod supplies application dependencies. The bootstrap loads native services, then passes them through a scoped provider. Providers that depend on those services explicitly declare their scoped dependencies, including the router. Small ChangeNotifier controllers expose synchronous UI state around asynchronous operations. GoRouter guards routes until onboarding is saved. The router is disposed with its provider. Native adapters are isolated from widgets and can be replaced by explicit test doubles in tests.

## Local state

SQLite schema version 7 preserves the original `learner_progress` row and `lesson_positions` for Days 2–5, plus `review_state`, `practice_attempts`, `salon_rehearsals` and `confidence_check_ins`. It stores onboarding step, profession, support language, current prompt index, review timing, authored attempted-prompt IDs, per-scenario best completed reply counts and longest recorded-answer seconds, and two optional 1–5 learner self-ratings. The repository uses parameterised queries. Changes become visible only after a successful database write; write failure preserves the previous state and exposes retry. These summaries show participation or self-report, not mastery or assessed lesson completion.

Reset atomically deletes all six local progress/review/attempt/rehearsal/check-in tables. It does not contact the backend or revoke earlier provider processing. Lesson, dialogue, baseline and Day-5 challenge audio caches are cleared before durable deletion, and failure is exposed for retry.

Future local changes must increment the schema version and provide tested upgrades. No remote database schema or credentials are introduced. Routine audio is separate cache data, excluded from learning history.

## Curriculum

`curriculum/alpha.json` is the editorial source of truth for the five Alpha days. `scripts/sync_curriculum.py` validates it and copies identical content into `mobile/assets/curriculum/alpha.json` and `backend/app/data/alpha.json`. CI checks both copies for drift. No symlinks outside the projects are required for packaging.

Day 1 has four authored prompts, ending in the blueprint's 30–60 second introduction. Days 2–5 contain objectives, target language and short authored practice sequences. Longer consultations remain unmeasured, and the fixed final challenge remains unscored. Example sentences are editorial seeds requiring educator review. They are not generated assessment data.

The seven baseline and five Day-5 fixed capture prompts are provisional teaching/assessment material. The generated salon visual is an aid to description, not a reference answer. The Day-5 task covers similar customer acts but has not been judged equivalent by educators. No measured result is inferred from recording completion.

## Voice boundary

`Microphone` provides permission, start, stop, discard, interruption and disposal operations. `NativeMicrophone` implements it through `record`, storing mono AAC in a private cache directory. `MicrophoneController` owns visible transitions and a 60-second limit. UI requires separate permission and start actions. Navigation or backgrounding ends active capture. A take stays available during in-app navigation until replaced/discarded; cache cleanup occurs on the next app launch.

The microphone processing state only represents local audio work. Recording success means a nonempty file exists; it does not mean a learner was understood. A separate, explicit upload action may return a transcript through the SpeakCraft backend. No score is computed or shown.

`flutter_tts` reads authored instructions/examples through the device speech engine. It does not send learner audio to an AI service. English voice availability depends on device settings, and offline voice availability varies. The UI offers text and a useful failure message. Reference speech does not establish an accent standard.

## Backend

`backend/app/main.py` defines an application factory, a typed `GET /health` endpoint and bounded, pilot-protected `POST /v1/speech/transcribe`, `POST /v1/speech/evaluate`, `POST /v1/kora/respond` and `POST /v1/salon/respond`. The factory accepts settings and test providers. Configuration comes from `SPEAKCRAFT_` variables plus a server-only `OPENAI_API_KEY`. Interactive docs and OpenAPI are disabled by default and opt in via `SPEAKCRAFT_DOCS_ENABLED=true`. No broad CORS policy or speculative learner-data routes are installed.

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
- [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
