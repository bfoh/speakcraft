# Sprint 7 validation — five-day guided practice

## Source and simulated journey

- Canonical curriculum and byte-identical mobile/backend assets: PASS. Days 2–5 now contain 3, 3, 3 and 4 authored prompts. Both validators require a complete sequence and unique prompt IDs.
- Backend Ruff, strict mypy and pytest: PASS (41 tests), including authoritative feedback context for every new daily sequence.
- Flutter formatting and analysis: PASS. All 62 Flutter tests pass, including migration, day switching and large-text Day-5 navigation.
- SQLite version-1 to version-2 upgrade test: PASS; Day-1 index survives, and new days start at the first prompt. Save and reopen tests cover independent day positions.
- Android debug APK: PASS.
- iOS native simulator journey: BLOCKED locally. Xcode's simulator build stalled twice and was interrupted; the first attempt logged an invalid saved account credential in the host keychain. There was no compiler diagnostic. Sprint 6's native journey passed before this host issue. The Sprint 7 native journey remains unverified.
- Generic iOS simulator build in CI: pending after push.
- `git diff --check`, canonical curriculum check and source secret scan: PASS.

## Product quality gate

**BLOCKED for a real learner pilot.** The authored examples need Ghanaian educator review, and the longer Day-3 consultation and Day-5 challenge remain unimplemented as assessed experiences. Live provider behavior and physical Android/iOS microphone, interruption, audio-route and accessibility checks require the later device session. The existing shared pilot token is only for internal testing; public access needs learner authentication, rate limits and provider retention review.

These pages provide guided practice, not a mastery or challenge score. Daily positions record navigation only; no voice, transcript or assessment result is saved by the migration.
