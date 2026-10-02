# Sprint 13 validation — saved guided-practice attempts

## Checks

- Curriculum copy check and `git diff --check`: PASS.
- Dart format, Flutter static analysis and full Flutter unit/widget suite: PASS (97 tests). The later privacy-reset assertion also passed in a focused rerun.
- SQLite tests cover fresh database, migration from versions 1–3, reopening, no inferred attempts from a saved position, and Clear phone data deletion.
- Widget tests cover skipping, recording and finishing all Day-2 steps, failed local save and retry, Home/My practice status and privacy reset.
- Android debug APK and iOS simulator app build: PASS. `flutter_tts` reports future Kotlin and iOS Swift Package Manager compatibility warnings; current builds pass.
- Backend Ruff format/lint, strict mypy and pytest: PASS (44 tests). No backend behavior changed.
- Native iOS simulator journey: BLOCKED on this host. The first run stopped at the OS microphone prompt. With simulator-only permission granted, a second run reached the new step-save behavior but failed an old expectation that its now-cleared temporary take would still exist. The assertion was corrected. A final rerun stalled after the Xcode build and ended with `Error waiting for a debug connection: The log reader failed unexpectedly`; it ran no tests. The app itself builds for iOS, but this final native journey remains unverified.

## SpeakCraft quality gate

**PASS for local guided-practice attempt tracking in source, unit and widget checks.** A nonempty native take plus explicit advance/save creates one authored prompt marker. Saved position alone never creates an attempt. SQLite writes position and markers atomically; a failed write keeps the current take and position for retry. Markers stay on the phone, work offline and are deleted by Clear phone data. The UI uses text and visible microphone states, without a score.

**BLOCKED for native journey confirmation and assessed lesson or challenge completion.** The simulator debug connection must be retried on a healthy host or checked on the physical device. The markers show participation only. They cannot establish that speech was understandable, that the Day-3 consultation lasted 90 seconds, or that the Day-5 customer task was completed. Physical Android/iOS microphone, audio route, interruption and screen-reader checks remain for the planned device session. Educator review and consented speech evaluation remain before a learner pilot.
