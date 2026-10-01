# Sprint 6 validation — Help Me Say It

## Source and simulated journey

- Backend Ruff formatting/lint, strict mypy and pytest: PASS (37 tests). The new tests cover authentication, fixed context, body/field bounds, provider refusal, safe errors, strict structured output and `store: false`.
- Flutter formatting and analysis: PASS. Flutter tests: PASS (58 tests), including the three stages and offline retry with the take intact.
- Canonical curriculum copies and `git diff --check`: PASS; this sprint changes no curriculum data.
- Android debug APK: PASS.
- iOS simulator native journey: PASS on iPhone 16 Pro / iOS 18.4. It used real SQLite and native recording with a local HTTP test server for the new expression contract and prior journeys. The Day-1 lesson recording survived the other voice flows.
- iOS simulator debug build: local generic-destination command was interrupted after eight minutes in Xcode without a compiler error. The native simulator test compiled and ran the same app successfully. CI will repeat the generic build.
- Source secret scan: PASS. The provider key is only read in FastAPI; the app receives an in-memory pilot access code. No learner text or audio logging was introduced.
- Backend wheel packaging: PASS; it contains the expression provider module and curriculum asset.

## Product quality gate

**BLOCKED for a real learner pilot.** No live provider key or consented learner recordings were available, so expression quality, meaning inference and teaching fit are unverified. A Ghanaian educator should review representative samples. Both physical devices still need microphone, interruption, audio-route and accessibility checks when connected.

The shared pilot token is limited to internal testing. Public access needs learner authentication, rate limits and a provider retention review. Device speech depends on an installed English voice. The plugin currently warns about future Android Kotlin and iOS Swift Package Manager compatibility, but the current debug builds pass.
