# Sprint 7 — Five-day guided practice

## Goal

Let an Alpha learner open all five authored daily lessons, practise their vocational language with voice, and resume the current prompt on the same phone. Keep the Day-5 challenge visibly distinct from a scored or complete assessment.

## Context

The canonical curriculum contains the blueprint's five days, but Home currently locks Days 2–5 and `LessonScreen` is hardwired to Day 1. Local SQLite stores only the Day-1 prompt index. Speech recognition and prompt-bound Kora feedback already resolve any canonical lesson prompt on the backend.

## Non-goals

No automatic mastery unlock, scored assessment, new AI provider, broader local-language support, content-management service or cloud sync. Do not present a single prompt as a completed 90-second consultation or full Day-5 scenario. Educator review of authored examples remains needed.

## User Journey

The learner sees five open daily cards. Each card names the day, objective and current practice. They open a day, listen to instructions and examples, record a take, optionally request transcription and feedback, and move among that day's authored prompts. Their current prompt is saved after the local database write. They may restart practice from the first prompt. Days 3 and 5 clearly point to the existing AI Salon for additional conversation practice without claiming task completion.

## Technical Approach

- Expand canonical curriculum with a few short, authored prompts for Days 2–5 and validate uniqueness/completeness; package identical mobile/backend copies.
- Generalise `LessonScreen` and route parameters to load a validated `Lesson` by day. Keep the existing microphone/feedback boundaries and ensure a recording from one day never appears under another prompt.
- Add a versioned SQLite migration for prompt positions of Days 2–5, preserving Day-1 onboarding and prompt index. Keep updates atomic and surface failures before UI confirms a new position.
- Replace locked Home cards with accessible daily entry controls. Keep the challenge description honest and link relevant days to AI Salon.

## Files / Components

Canonical curriculum and sync validator; Flutter curriculum, storage, router, Home, lesson screen and tests; native SQLite migration/integration test; architecture, privacy, decisions, README and validation record.

## Data Model

SQLite schema version 2 adds a `lesson_positions` table for Days 2–5, with one nonnegative prompt index per day. Migration defaults existing learners to the first practice in each new day and leaves Day-1 state intact. No scores, completion timestamps or audio are saved.

## API Contract

No new endpoint. `POST /v1/speech/evaluate` already accepts canonical `lesson_id` and `prompt_id`, and backend lookup continues to reject unknown combinations. The expanded curriculum is packaged with the backend.

## Privacy / Security

Only daily prompt indices are persisted. Recordings remain private cache files and are deleted when switching days/prompts as appropriate. Upload remains an explicit learner action behind the existing internal pilot bearer. No key enters Flutter and no learner text is added to logs.

## Offline Behaviour

All five daily cards, authored words, device speech where installed, recording and saved prompt positions work offline. Transcription and AI feedback require the configured backend and keep the current take for retry after failure.

## Android / iOS Considerations

The same Flutter routes and SQLite migration run on both. Verify permissions, audio interruptions, small screens, text scaling and route changes in tests. Run both debug builds and available native simulator flow. Physical device checks wait for connected devices.

## Milestones

1. Add reviewed-shaped authored practice data and shared validation.
2. Migrate local progress and generalise lesson route/screen.
3. Open all daily cards with honest challenge labels.
4. Add tests and run the quality gate.

## Acceptance Criteria

- Every day opens its own authored instructions and examples with audio controls.
- The learner can record locally, review a transcript and ask for prompt-bound feedback from any day when connected.
- Day positions survive app restart and migration preserves an existing Day-1 position.
- Switching days never displays or uploads a prior day's take under the new prompt.
- Offline use preserves authored practice and saved position; network failure preserves the current take.
- No day card claims mastery or a completed consultation from opening a practice page.
- Flutter/backend tests and Android/iOS debug builds pass.

## Validation

```sh
python3 scripts/sync_curriculum.py --check
backend/.venv/bin/ruff format --check backend scripts
backend/.venv/bin/ruff check backend scripts
backend/.venv/bin/mypy --config-file backend/pyproject.toml backend/app
backend/.venv/bin/pytest -c backend/pyproject.toml backend/tests
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
flutter test integration_test/foundation_test.dart -d <simulator-id>
```

## Risks / Unknowns

- The blueprint gives daily objectives but limited scripted prompt detail. Added examples require educator review and should not be treated as validated pedagogy.
- A full Day-3 consultation and Day-5 challenge still need richer scenario and assessment design.
- Physical devices and live provider behavior remain unavailable in this environment.

## Decision Log

- 2026-10-02: Open structured daily phrase practice without claiming completion or requiring an artificial mastery gate.
- 2026-10-02: Keep the existing Day-1 column and migrate to a separate table for Days 2–5. A transaction saves all positions with the onboarding row, and a version-1 upgrade test protects existing progress.
- 2026-10-02: A shared lesson recorder keeps the current take only for its exact prompt ID. Switching days clears another prompt's take and transcript before that data can be shown or uploaded.

## Progress

- [x] Read the five-day blueprint objectives and current curriculum/storage boundaries.
- [x] Expand and validate daily practice data.
- [x] Migrate daily positions and generalise mobile flow.
- [~] CI generic iOS build and final quality record; all 62 Flutter tests pass. The local native simulator build stalled twice in Xcode and was interrupted, so this journey remains unverified here.
- [ ] Live provider, educator and physical-device review before pilot.
