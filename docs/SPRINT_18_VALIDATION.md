# Sprint 18 validation — unscored Day-5 challenge

## Checks

- `python3 scripts/sync_curriculum.py --check`: PASS; canonical, mobile and backend curriculum bytes match.
- `dart format --output=none --set-exit-if-changed lib test integration_test`: PASS.
- `flutter analyze`: PASS.
- `flutter test`: PASS, 124 tests. Focused cases cover curriculum identity, separate launch-time-expiring audio folders, failed save/retry, replay, clearing, route gating, denied permission and 320-pixel enlarged-text UI.
- `flutter build apk --debug`: PASS.
- `flutter build ios --simulator --debug`: PASS.
- Backend Ruff format/lint, mypy and pytest: PASS, 44 tests. No backend API was added.
- Local Markdown links and `git diff --check`: PASS.
- GitHub CI: PASS ([Sprint quality run](https://github.com/bfoh/speakcraft/actions/runs/37065756424)); backend, mobile and iOS jobs passed.

## SpeakCraft quality gate

**PASS for the unscored software slice.** The learner can complete the fixed Day-5 task offline after guided practice. The app validates authored IDs, isolates Day-1 and Day-5 audio, retains an unsaved take on failure, deletes temporary audio on next launch/clear, and makes no backend request or score. Android/iOS builds pass. `flutter_tts` emitted future Kotlin Gradle Plugin and iOS Swift Package Manager compatibility warnings; current builds passed. The prompt wording, task equivalence, device audio and learner comprehension still need the external and final-device gates in [pilot readiness](PILOT_READINESS.md).
