# Sprint 8 validation — scenario-bound salon progression

## Source and simulated journey

- Canonical curriculum and byte-identical mobile/backend assets: PASS. Three authored scenarios specify goal, customer goal/personality, difficulty, learner objectives, target language, opening, success conditions and bounded turns.
- Backend Ruff formatting/lint, strict mypy and pytest: PASS (44 tests). Tests cover scenario authority, altered openings, six-turn history bounds, provider-agnostic customer instructions, safe failures and `store: false`.
- Flutter formatting, analysis and tests: PASS (64 tests). The Day-3 and Day-5 routes open distinct customer scenarios, and the six-turn controller stops at the authored limit. Existing offline retry and small-screen flows still pass.
- Android debug APK: PASS.
- Generic iOS simulator build in CI: PASS ([run 36960468162](https://github.com/bfoh/speakcraft/actions/runs/36960468162)). Backend and Android/mobile jobs passed in the same run.
- iOS native simulator journey: BLOCKED locally. Xcode's simulator build stalled twice during Sprint 7; one attempt logged an invalid saved account credential. The Sprint 6 native voice journey passed before this host issue. The new scenarios need a later native run on a repaired host or connected devices.
- `git diff --check`, canonical curriculum check and source secret scan: PASS. Backend wheel packaging: PASS; the packaged asset contains all three scenarios.

## Product quality gate

**BLOCKED for a real learner pilot.** The authored Day-3 and Day-5 scenarios and generated customer behavior need Ghanaian educator review. Finishing the dialogue records no duration or validated success measure, so the app does not claim completion of a 90-second consultation or scored final challenge. Live provider calls and physical Android/iOS microphone, interruption, audio-route and accessibility checks remain for the device session.

The internal pilot bearer is still shared. Public access needs learner authentication, rate limits and provider retention review. Dialogue, voice and transcripts remain transient; no new persistent learner data was added.
