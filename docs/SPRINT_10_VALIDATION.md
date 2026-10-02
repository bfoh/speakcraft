# Sprint 10 validation — offline My Words review

## Source and simulated journey

- Curriculum validation and byte-identical mobile/backend assets: PASS. Ten review items have stable IDs, a day, phrase and cue; duplicate IDs are rejected.
- Backend Ruff format/lint, strict mypy and pytest: PASS (44 tests). Backend API behavior is unchanged. The backend wheel includes the updated curriculum asset.
- Flutter formatting and static analysis: PASS. Full Flutter unit/widget suite: PASS (81 tests), including the no-due deck and pending-write coordination.
- SQLite version 1 and 2 upgrade tests, persisted review reopen, clear-phone deletion, scheduler intervals, failed write/retry, pending-write coordination, offline screen navigation and large-text layout: PASS.
- Android debug APK: PASS. `flutter_tts` emits a future Kotlin plugin compatibility warning; current build succeeds.
- Generic iOS simulator build: pending CI after push. Local native simulator still stalls on the host Xcode credential/toolchain issue recorded in Sprint 7.
- `git diff --check` and mobile source secret scan: PASS.

## Product quality gate

**BLOCKED for a real learner pilot.** My Words is a useful offline self-rated review flow, but the authored phrases and interval assumptions need Ghanaian educator/learner review. It does not measure pronunciation or retention. Physical Android/iOS speech, interruption and screen-reader checks remain for connected devices. Live provider quality and the shared pilot bearer limitation from earlier slices remain unresolved.
