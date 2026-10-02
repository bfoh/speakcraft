# Sprint 13 — Saved guided-practice completion

## Goal

Let learners see which of the five daily guided practices they have actually attempted, with progress that survives app restarts and works offline.

## Context

The five-day curriculum has three or four authored speaking prompts per day. Today, `Next practice` saves only a position and can skip a prompt. The Day-3 and Day-5 AI Salon scenarios exist, but neither is a measured or assessed challenge. The blueprint calls for basic learner progress and eventually at least four of five lessons completed in a pilot.

## Non-goals

No speaking score, learning-success claim, 90-second consultation claim, Day-5 assessed challenge, remote analytics, account, raw-audio retention, or AI change. The existing AI Salon remains optional conversation practice.

## User Journey

A learner hears a prompt, records a take, and uses `Next practice` to move on. The app saves an attempt marker for that prompt when the learner advances. They may move on without recording, but the day remains unfinished. On the last prompt, `Save practice` records that attempt. When every prompt has a saved attempt marker, Home and My practice show `Practice steps finished`. The learner can repeat any day. If the local write fails, the current take and position remain available for retry.

## Technical Approach

- Store only authored prompt IDs that received a successfully saved local recording and an explicit advance/save action. Derive a day's finished state from all current curriculum prompt IDs, so content additions do not silently inherit completion.
- Migrate local SQLite to version 4 with a small `practice_attempts` table, saving markers in the same transaction as position changes.
- Update the lesson's final step and Home/My practice status. Keep the distinction between attempted guided practice and assessed communication clear, particularly for Days 3 and 5.
- Preserve the existing ability to skip and return; finishing requires recordings for missed steps on a later pass.

## Files / Components

`mobile/lib/core/storage/`, lesson, Home and progress screens, mobile tests, architecture/privacy/decision documentation.

## Data Model

SQLite `practice_attempts(prompt_id TEXT PRIMARY KEY)`. IDs come from validated authored curriculum. No audio, transcript, score, timestamp, or identifier is stored. Clear phone data deletes the table. Version 1–3 migrations preserve existing positions and review state.

## API Contract

No API changes. No attempt marker is sent to the backend.

## Privacy / Security

Markers reveal which activities were attempted and stay in the app-private SQLite database. Existing recording cache expiry and Privacy deletion remain. Never derive speech quality from a marker.

## Offline Behaviour

Recording and local completion work offline. A failed local write leaves the take and location in place.

## Android / iOS Considerations

The same Flutter/SQLite implementation serves both platforms. Build both. Native mic permissions and audio route checks remain for connected devices.

## Milestones

1. Add immutable attempt state, SQLite migration and persistence tests.
2. Connect recording evidence to daily navigation and visible status.
3. Run Flutter format/analyze/tests, native builds and the quality gate.

## Acceptance Criteria

- Skipping a prompt never marks it attempted or finishes a day.
- Advancing after a successful recording durably marks only that prompt.
- A day shows `Practice steps finished` only after all its authored prompts have recorded attempts.
- Reopening the app retains markers; Clear phone data removes them.
- Failed saves retain the recording and previous position for retry.
- Days 3 and 5 do not claim an assessed consultation or challenge.
- Android and iOS compile, and relevant tests pass.

## Validation

```sh
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

## Risks / Unknowns

- A nonempty audio file proves an attempt was recorded, not that the learner said the target words or communicated successfully.
- Existing devices may have progressed through prompts without recording; migration must not infer attempts from saved position.
- The 90-second Day-3 consultation and assessed Day-5 challenge still need separate validated work.

## Decision Log

- 2026-10-02: Use authored prompt IDs, rather than a position or a duration, as the durable evidence of attempted guided practice. Label the result as finished practice steps, never as a speaking score.
- 2026-10-02: Home must listen to `SessionController` to refresh after returning from a lesson. A widget test exposed its previously stale progress display.
- 2026-10-02: The final iOS native rerun was blocked by the simulator log reader after Xcode compiled. The first permission-gated run and the obsolete smoke assertion were corrected; no physical device was touched.

## Progress

- [x] Inspect blueprint, repository guidance and current journey.
- [x] Implement persistence and UI.
- [x] Run format, analysis, unit/widget tests, Android APK and iOS simulator builds; update documentation.
- [ ] Confirm the final native journey on a working simulator or physical device.
