# Sprint 18 — Unscored Day-5 salon challenge

## Goal

Give learners a fixed Day-5 customer exchange they can record and review after practice. Keep the prompts close enough to the Day-1 customer tasks for educator review, without claiming measured improvement.

## Context

The Day-1 starting assessment has seven fixed local recordings. Day 5 has guided practice and an AI Salon, but its variable dialogue cannot serve as a directly comparable assessment. The Blueprint asks for a structured final challenge and English Mirror comparison over time. The draft rubric requires expert review before results.

## Non-goals

No score, automatic evaluation, durable audio history, upload/export, 90-second success claim, provider call, new backend endpoint or English Mirror improvement claim. This implementation does not establish statistical equivalence between Day 1 and Day 5.

## User Journey

After Day-5 practice, the learner opens an optional Salon Challenge. They listen to four fixed customer lines, record a response to each, replay it and save it for the current app session. A final page lets them replay or clear the four answers. It says that no result is available yet. Privacy reset also clears the audio.

## Technical Approach

Author four Day-5 items in canonical curriculum data and validate/order them in Python and Dart. Reuse the assessment recording/controller/playback abstractions with a separate temporary capture directory and microphone instance. Parameterise the existing screen by challenge type where this keeps the same permission, interruption and recovery behavior. Keep stage-specific labels and hide the starting confidence check-in on Day 5 (it remains after guided practice).

## Files / Components

`curriculum/alpha.json`, curriculum synchronizer and mobile parser, assessment capture store/controller/screen, services and router, Day-5 lesson entry point, Privacy reset, tests, README, architecture, privacy and validation docs.

## Data Model

Four authored `day5_challenge_items` with ID, task title, instruction and spoken customer prompt. Captured `.m4a` files live in a separate private temporary directory, removed at next app launch or explicit clear. No SQLite or remote record of challenge completion.

## API Contract

None. Challenge audio remains local and is never sent to the backend.

## Privacy / Security

Starting and Day-5 takes cannot overwrite each other. Clear phone data removes both sets. The app makes no proficiency or progress claim. File names come only from validated authored IDs.

## Offline Behaviour

The entire challenge works offline. A failed save keeps the take for retry. A failed clear does not claim deletion.

## Android / iOS Considerations

Use the same native microphone and device speech interfaces on both platforms. Check simulator builds and lifecycle/widget tests now. Physical audio, permission and device route checks remain the final task by user request.

## Accessibility

Large labelled controls, spoken customer prompt, text copy, visible recording state, replay and error notices. Test enlarged text on a small viewport.

## Milestones

1. Author and validate bounded Day-5 challenge prompts.
2. Add isolated transient recording/playback flow and Day-5 navigation.
3. Extend privacy/reset and exercise failure, offline and small-screen paths.
4. Run formatting, analysis, Flutter/backend tests, Android/iOS builds and CI.

## Acceptance Criteria

- Day 5 opens four fixed customer prompts after guided practice and makes no provider request.
- Each response can be recorded, replayed and saved independently; save failure preserves the take.
- Starting recordings and Day-5 recordings are isolated.
- Final review and Privacy reset can clear challenge answers, with deletion failures visible.
- Relaunch removes the temporary audio.
- The UI makes no score or improvement claim.

## Validation

`python3 scripts/sync_curriculum.py --check`; Flutter `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, `flutter build ios --simulator --debug`; backend Ruff/mypy/pytest; `git diff --check`; GitHub CI.

## Risks / Unknowns

Prompt equivalence and the local realism of customer responses need vocational and language-educator review. The app-session lifetime prevents durable English Mirror comparison by design. Physical-device behavior and target-learner comprehension remain unverified until final testing.

## Decision Log

- 2026-10-02: Use a separate, unscored fixed task with transient audio. Keep the variable AI Salon as practice.

## Progress

- [x] Plan and inspect existing assessment/curriculum architecture.
- [x] Author and validate items.
- [x] Implement flow and tests.
- [x] Run quality checks and CI. [Sprint quality run](https://github.com/bfoh/speakcraft/actions/runs/37065756424) passed all three jobs.
- [ ] Physical-device acceptance remains the final task.
