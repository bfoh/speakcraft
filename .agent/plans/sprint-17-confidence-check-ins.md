# Sprint 17 — Learner confidence check-ins

## Goal

Let learners report, in their own words, how ready they feel to help a customer in English after the starting assessment and after Day 5 practice. Save each response locally without presenting it as a speaking score.

## Context

The Blueprint lists confidence self-rating (1–5) as a supporting Alpha measure. The research-derived rubric says confidence cannot be inferred from a recording. The app currently captures starting answers, five days of practice and local progress but has no direct confidence response.

## Non-goals

No automatic confidence inference, proficiency score, assessed Day-5 challenge, audio retention, backend endpoint, analytics upload or implication that a rating proves improvement. This does not collect learner responses for rubric validation.

## User Journey

After the seven starting recordings, the learner can optionally answer one short question: “How ready do you feel to help a customer in English today?” They choose 1–5, hear the question if useful and see a saved confirmation. After finishing Day 5's four practice steps, the same question appears. My practice shows the two choices as self-ratings. The learner may update a choice; the latest rating and time are kept on this phone. Clear phone data removes them.

## Technical Approach

Add a small reusable check-in component with labelled, accessible choices and optional device speech. Add a local progress model for stage, value and timestamp, persisted through a versioned SQLite migration. Keep each stage optional. On save failure, leave the earlier value visible and show a retry message. Use the same wording and scale on both screens.

## Files / Components

Mobile progress model/store and SQLite migration, assessment and Day-5 lesson screens, My practice, Privacy copy, shared component, widget/store tests, architecture/privacy/decision documentation.

## Data Model

SQLite `confidence_check_ins`: `stage` (`starting` or `day5`) primary key, `rating` integer 1–5, `rated_at` UTC epoch milliseconds. No identity, audio or transcript. Existing records migrate to no check-in rather than an inferred value. Clear phone data removes this table.

## API Contract

No backend API or provider call. A check-in is never uploaded by this feature.

## Privacy / Security

The response is local learning history and can be deleted with phone data. Do not log it or infer confidence from voice. A rating is the learner's own statement, not a professional assessment.

## Offline Behaviour

Choosing and reviewing a rating work offline. SQLite save must complete before confirmation. Failed writes remain retryable.

## Android / iOS Considerations

Shared Flutter UI and SQLite behavior. Use the existing device speech output for optional spoken guidance. Check responsive layout, semantics and both simulator/build targets; physical-device testing remains the final task by user instruction.

## Milestones

1. Add model, SQLite migration and persistence/failure tests.
2. Add shared check-in component and starting/Day-5 entry points.
3. Show self-ratings in My practice and update privacy/documentation.
4. Run formatting, analysis, tests, Android and iOS builds, quality gate and CI.

## Acceptance Criteria

- The same short question and 1–5 labels appear after starting assessment and finished Day 5 practice.
- Both check-ins are optional, clearly self-reported, and readable with text/audio.
- A saved value persists through app restart; an older database migrates with no fabricated value.
- Save failure leaves the previous confirmed rating and offers retry.
- My practice shows each available rating without a measured improvement claim.
- Clear phone data removes both check-ins.
- No recording or backend request is created by a check-in.

## Validation

```sh
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Also run `python3 scripts/sync_curriculum.py --check`, backend configured checks and `git diff --check`. Review CI after pushing.

## Risks / Unknowns

- Self-report may change with context and is not a measure of speaking ability.
- The specific English question and five response labels need target-learner review; the component must remain simple and audio-accessible.
- Physical accessibility and voice checks are deferred until the user's final device-testing task.

## Decision Log

- 2026-10-02: Capture learner-reported readiness at starting and Day 5 points. Keep the latest response per stage with a timestamp; show the two separately and do not compute an improvement claim.

## Progress

- [x] Read Blueprint, instructions, skills and current storage/UI.
- [x] Implement check-ins and tests.
- [x] Run quality checks and update documentation.
- [x] Push and verify CI.
- [ ] Physical-device acceptance remains the final task.
