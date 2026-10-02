# Sprint 10 validation — offline My Words review

## Source and simulated journey

- Curriculum validation and byte-identical mobile/backend assets: PASS. Ten review items have stable IDs, a day, phrase and cue; duplicate IDs are rejected.
- Backend Ruff format/lint, strict mypy and pytest: PASS (44 tests). Backend API behavior is unchanged. The backend wheel includes the updated curriculum asset.
- Flutter formatting and static analysis: PASS. Full Flutter unit/widget suite: PASS (83 tests), including the no-due deck, pending-write coordination, load-failure retry and audio-disposal regression.
- SQLite version 1 and 2 upgrade tests, persisted review reopen, clear-phone deletion, scheduler intervals, failed write/retry, pending-write coordination, offline screen navigation and large-text layout: PASS.
- Android debug APK: PASS after the audio fix. `flutter_tts` emits a future Kotlin plugin compatibility warning; current build succeeds.
- Generic iOS simulator build, backend and Android/mobile jobs: PASS on the pre-fix code commit in [CI run 36962910442](https://github.com/bfoh/speakcraft/actions/runs/36962910442). Final fix CI is pending after push.
- Local iOS simulator build and native smoke journey: PASS. The full onboarding, recording, fake API, Kora/Salon/Help Me Say It and My Words journey ran with real SQLite and recording. The first run exposed a shared audio-button `dispose()` bug; after caching the speech output before disposal and granting simulator microphone permission, the rerun passed. Physical-device checks remain separate.
- `git diff --check` and mobile source secret scan: PASS.

## Product quality gate

**BLOCKED for a real learner pilot.** My Words is a useful offline self-rated review flow, but the authored phrases and interval assumptions need Ghanaian educator/learner review. It does not measure pronunciation or retention. Physical Android/iOS speech, interruption and screen-reader checks remain for connected devices. Live provider quality and the shared pilot bearer limitation from earlier slices remain unresolved.
