# Sprint 12 validation — unscored baseline capture

## Checks

- Canonical curriculum validation and byte-identical mobile/backend copies: PASS. Version 0.1.1 has seven fixed, bounded assessment recording items across the blueprint's five parts.
- Flutter formatting and static analysis: PASS. Full unit/widget suite: PASS (93 tests). Tests cover content order, private copy/startup purge, unsafe ID rejection, all seven captures, navigation within the same session, save failure and retry, pending-write coordination, Privacy deletion failure and retry, microphone permission, unavailable voice and enlarged text.
- Android debug APK and iOS simulator app build: PASS. `flutter_tts` warns about future Android Kotlin and iOS Swift Package Manager compatibility; current builds pass.
- Native iOS simulator smoke journey: PASS after granting microphone permission to the simulator. It recorded an assessment answer with the native recorder, staged a nonempty file, and completed the pre-existing lesson, Kora, salon, Help Me Say It and My Words checks. The first attempt was stopped at the OS permission prompt; no physical device was used.
- Backend Ruff format/lint, strict mypy and pytest: PASS (44 tests). No backend assessment endpoint or behavior was added.
- `git diff --check` and mobile source credential scan: PASS.

## SpeakCraft quality gate

**PASS for this unscored capture slice.** The learner can record all five parts, see clear state and retry errors, and clear temporary files. The app does not upload, score or retain a comparable baseline.

**BLOCKED for learner-pilot assessment claims.** The generated salon picture and authored prompts need Ghanaian educator review. There is no reviewed rubric, consent/retention policy for a durable baseline, or validated Day-5 comparison. Physical Android and iOS microphone, audio route, interruption and screen-reader checks remain for the planned device session. Live provider quality also remains unverified with consented learner samples.
