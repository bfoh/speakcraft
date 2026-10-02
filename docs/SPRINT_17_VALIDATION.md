# Sprint 17 validation — learner confidence check-ins

## Checks

- Dart formatting and Flutter static analysis: PASS.
- Focused Flutter storage and app widget tests: PASS (62 tests). These include local save/reopen, old-database migration, invalid ratings, failed-save retry, both entry points and Privacy reset.
- Full Flutter suite: PASS (118 tests), including the 320-pixel enlarged-text check.
- Android debug APK: PASS (`flutter build apk --debug`). Flutter warned that `flutter_tts` still applies the Kotlin Gradle Plugin; track compatibility before a future Flutter upgrade.
- iOS simulator build: PASS (`flutter build ios --simulator --debug`). Flutter warned that `flutter_tts` lacks Swift Package Manager support; track compatibility before a future Flutter upgrade.
- Backend Ruff format/lint, strict mypy, pytest (44 passed) and canonical curriculum check: PASS. No backend or curriculum change.
- GitHub CI: PENDING.

## SpeakCraft quality gate

**PASS for this implementation.** The feature stores two optional self-reports locally with timestamps. It does not derive a speaking score, retain audio or call the backend. The question and response labels still need target-learner language review. Physical audio, accessibility and permission behavior will be tested last, after the other Alpha work, as requested.
