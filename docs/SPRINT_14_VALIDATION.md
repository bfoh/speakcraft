# Sprint 14 validation — AI Salon rehearsal progress

## Checks

- Dart format and Flutter analysis: PASS.
- Full Flutter unit/widget suite: PASS (102 tests). Added tests for early provider endings, a four-reply Day-3 exchange, unsaved partial exchanges, failed local save/retry, schema-version-4 migration, reopen, best-count monotonicity and phone-data removal. A focused rerun also checked the new end screen at 320-pixel width and enlarged text.
- Android debug APK: PASS. `flutter_tts` warns about future Kotlin plugin compatibility; the current build succeeds.
- iOS simulator app build: PASS. `flutter_tts` warns about future Swift Package Manager compatibility; the current build succeeds.
- Backend Ruff format/lint, strict mypy and pytest: PASS (44 tests). No backend/API change was made.
- Canonical curriculum validation and byte-identical packaged assets, `git diff --check`, and mobile credential scan: PASS.

## SpeakCraft quality gate

**PASS for local rehearsal-count behavior in source and automated tests.** Only Day-3/Day-5 terminal conversations publish an actual learner-reply count. A provider ending early saves a shorter count. The best count survives reopening; a shorter later run does not lower it. Failed local persistence leaves the dialogue and retry visible. The count remains on the phone and is deleted by Clear phone data. The end screen offers authored goals with text and audio for self-review and explicitly says they are not a score.

**BLOCKED for assessed customer communication and real-device acceptance.** Reply count does not establish understanding, successful completion of the scenario goals, or a 90-second Day-3 consultation. Live model and transcription quality with consented Ghanaian learners is unverified. Physical Android/iOS permissions, interruptions, audio routes and accessibility remain for the user's planned device session. The earlier iOS simulator integration runner has a host log-reader failure; source/build checks do not replace native behavior testing.
