# Sprint 15 validation — recorded answer time

## Checks

- Dart formatting and Flutter static analysis: PASS.
- Full Flutter unit/widget suite: PASS (107 tests), including a measured 15-second salon take displayed on the end screen and Home. Focused microphone, conversation, storage and app reruns also passed.
- Android debug APK: PASS. `flutter_tts` warns about future Kotlin plugin compatibility; the current build succeeds.
- iOS simulator app build: PASS. `flutter_tts` warns about future Swift Package Manager compatibility; the current build succeeds.
- Backend Ruff format/lint, strict mypy and pytest: PASS (44 tests). No backend or API code changed.
- Curriculum validation, `git diff --check` and mobile credential scan: PASS.

## SpeakCraft quality gate

**PASS for the local recorded-answer summary in source and automated tests.** A monotonic stopwatch covers only native capture. Failed, discarded or replaced recordings cannot contribute to a rehearsal. A provider failure does not add time, and a retry adds the accepted take once. Version-5 reply counts migrate without fabricated time; reopening and Clear phone data are tested. The summary contains seconds and reply counts, not recordings, transcripts or a score. The Day-3 end screen explains that it does not time the full consultation.

**BLOCKED for native and assessed customer-communication acceptance.** A simulator build verifies compilation but not the microphone, interruptions, audio routes or screen readers on physical Android and iOS devices. The live speech/provider path and the blueprint's 90-second consultation outcome still need consented device testing and educator review. This duration may include silence and excludes customer speech.
