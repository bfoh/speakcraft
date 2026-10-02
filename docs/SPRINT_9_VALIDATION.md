# Sprint 9 validation — saved practice and local privacy

## Source and simulated journey

- Flutter formatting and static analysis: PASS.
- Flutter unit and widget tests: PASS (71 tests in the clean-checkout CI run). Tests cover SQLite deletion after reopen, failed deletion/retry, five-day resume navigation, confirmation/cancel, recorder cleanup, cleanup failure/retry and enlarged text on a 320-pixel display.
- Curriculum asset parity and `git diff --check`: PASS. Mobile source scan found no provider key or embedded pilot token.
- Android debug APK: PASS. Flutter reports a future Kotlin plugin compatibility warning from `flutter_tts`; it did not block the build.
- Generic iOS simulator build: PASS in [CI run 36961286281](https://github.com/bfoh/speakcraft/actions/runs/36961286281), along with backend and Android/mobile jobs. Local native simulator remains blocked by the host Xcode credential/toolchain stall already recorded in Sprint 7.
- Backend code and API contracts are unchanged. The preceding Sprint 8 CI run passed backend checks and tests.

## Product quality gate

**BLOCKED for a real learner pilot.** The new screens make no speaking-score or completion claim, but local deletion needs physical Android and iOS checks, including interruption, accessibility speech, large text and relaunch. Live provider behavior and Ghanaian educator review are still missing. Local erasure does not revoke earlier provider processing or remove OS backups. The pilot bearer remains shared and internal only.
