# Sprint 1 validation record

Checked 2026-09-30 on macOS 15.8 Intel with Flutter 3.47.5, Dart 3.13.4, Xcode 16.3, Java 17 and Android SDK 36. The commands below were run from the repository root unless noted.

## Automated checks

| Check | Result | Evidence |
| --- | --- | --- |
| Curriculum asset | PASS | `python3 scripts/sync_curriculum.py --check`; five days validated and mobile asset byte-identical. |
| Flutter formatting | PASS | `cd mobile && dart format --output=none --set-exit-if-changed lib test integration_test`. |
| Flutter analysis | PASS | `cd mobile && flutter analyze`; zero issues after correcting three style warnings. |
| Flutter tests | PASS | `cd mobile && flutter test`; 23 unit/widget tests after adding a production-bootstrap regression. Covers onboarding/Home/Day 1, local SQLite reopen, write failure, permission denial, recorder failures, interruption, repeated taps, 60-second stop, routing and initial accessibility checks. |
| iOS native journey | PASS | `cd mobile && flutter test integration_test/foundation_test.dart -d BB727569-6977-4D3D-92E4-859BE36760BA`; one end-to-end test on an iPhone 16 Pro simulator (iOS 18.4). Uses the production bootstrap, real SQLite, microphone permission and a nonempty local recording, then deletes the take. |
| Backend formatting and lint | PASS | `backend/.venv/bin/ruff format --check backend scripts` and `backend/.venv/bin/ruff check backend scripts`. |
| Backend type check | PASS | `backend/.venv/bin/mypy --config-file backend/pyproject.toml backend/app`. |
| Backend tests | PASS | `backend/.venv/bin/pytest -c backend/pyproject.toml backend/tests`; 6 tests. The installed Starlette emits an httpx TestClient deprecation warning; tests pass. |
| Live HTTP | PASS | Started Uvicorn and verified `/health` JSON and that OpenAPI contains only `/health` with opt-in docs. |
| Git whitespace | PASS | `git diff --check`. |

## Native builds and device checks

- Android: `cd mobile && flutter build apk --debug` **PASS**. Built `mobile/build/app/outputs/flutter-apk/app-debug.apk` with Android SDK 36 / Java 17. The first build took about 12 minutes while Gradle downloaded SDK components; the final incremental build after the scoped-provider fix passed in 35 seconds.
- iOS simulator: `cd mobile && flutter build ios --simulator --debug` **PASS**. Built `mobile/build/ios/iphonesimulator/Runner.app` with Xcode 16.3 and an iOS 15 deployment minimum. CI repeats Android and iOS simulator builds from a fresh checkout.

Flutter warns that `flutter_tts` still applies the Kotlin Gradle plugin, which a future Flutter version will reject without plugin migration. The current pinned Flutter 3.47.5 build succeeds. Android command-line SDK tooling also reports an XML version mismatch warning; it did not block the build.
Flutter also warns that `flutter_tts` does not yet support Swift Package Manager for iOS. CocoaPods builds pass with the pinned Flutter version; revisit this dependency before upgrading Flutter.

The iOS simulator booted on a second attempt. Installing and launching the first build exposed a Riverpod provider-scope startup error that widget tests had missed; the app showed Flutter's debug error screen. Explicit scoped dependencies and a production-bootstrap regression test fixed it. The corrected app launched to Welcome on an iPhone 16 Pro simulator running iOS 18.4; a screenshot was visually inspected. The native journey then passed through onboarding, Home and Day 1, saved local progress in SQLite, recorded through the iOS microphone plugin, and deleted the take. The test waits for asynchronous permission and recording transitions. No physical-device microphone or screen-reader behavior is claimed here until tested.

Before a learner pilot, run the native integration test on Android with microphone permission granted, then manually verify denial/revocation, phone interruptions, Bluetooth and wired audio routes, VoiceOver/TalkBack, small screens, large text, offline speech voice availability and relaunch/resume on both platforms. Record outcomes against the exact OS and device model.

## Scope and quality status

**SpeakCraft quality gate: PASS for the Sprint 1 foundation.** The requested learner path, local persistence, microphone state handling, curriculum structure, backend health contract, formatting, analysis, tests and both native builds pass. The iOS simulator exercises native capture. Android device recording, physical audio routes, permission revocation and screen-reader use remain explicit pre-pilot checks; this gate does not claim those untested outcomes.

The Sprint 1 build did not transcribe or evaluate speech. A successful local recording meant a nonempty cache file was saved. The assessment introduction produces no assessment result. Days 2–5 are data only. Support language is English pending reviewed translations. Neither development builds nor tests establish learning efficacy. Later speech work is recorded separately.
