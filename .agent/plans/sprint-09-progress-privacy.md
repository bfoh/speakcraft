# Sprint 9 — Honest progress and local privacy controls

## Goal

Let learners see where to resume each of the five days and understand what SpeakCraft keeps on their phone. Give them a clear, confirmed way to erase local progress and current recordings.

## Context

SpeakCraft stores onboarding choices and daily prompt positions in SQLite, and keeps current takes in private cache. Home shows some positions, but there is no dedicated Progress or Settings / Privacy screen from the blueprint. The app has no validated speaking score or durable lesson history.

## Non-goals

No mastery chart, fabricated skill score, streak, cloud account, provider-side deletion claim, analytics, English Mirror retention or new backend service. Do not call a saved prompt index a completed lesson.

## User Journey

The learner opens Progress from Home and sees the current practice in each day, with a button to continue. A short notice explains that this is their saved place, not a speaking score. From Home they can open Privacy, hear/read what stays on the phone and what is sent when they choose transcription or AI feedback, then choose Clear phone data. A confirmation names the data to be removed. After success, the app returns to Welcome with no saved onboarding or daily position. A local failure shows a retryable message.

## Technical Approach

- Add feature-oriented Progress and Privacy screens using existing large components and device speech.
- Extend `ProgressStore` with an atomic `clear()` and `SessionController` with a reset operation that only publishes default state after durable deletion. SQLite deletes both progress tables in one transaction; memory test store mirrors behavior.
- Before reset, stop and discard both native recorders, clear in-memory transcript/feedback/access code and invalidate transient dialogue state. Do not contact the backend.
- Keep GoRouter onboarding protection; after successful reset, navigate to Welcome.

## Files / Components

Flutter storage interface/SQLite adapter, screens, router/Home links, tests, docs and validation record. No backend or curriculum change.

## Data Model

No new fields. Reset deletes the `learner_progress` row and `lesson_positions` rows. Relaunch uses the default onboarding step and first prompt in each day.

## API Contract

No new endpoint. Clearing local data cannot reverse previous provider requests; the UI states that boundary plainly.

## Privacy / Security

The reset action is local, confirmed and irreversible to the learner. It clears current audio takes and the in-memory pilot access code. No secret is persisted or sent. If deletion fails, do not claim success or change the saved position shown in memory.

## Offline Behaviour

Progress, privacy explanation and local data deletion work without connectivity. No background upload or server request occurs.

## Android / iOS Considerations

Use shared Flutter UI and existing native cache/SQLite adapters. Test large text, touch controls and failed local writes. Run Android/iOS debug builds. Physical checks wait for connected devices.

## Milestones

1. Add durable clear operation and migration-safe tests.
2. Add Progress and Privacy routes with accessible controls.
3. Verify confirmation, success, failure and no-score wording.
4. Run quality gate and update docs.

## Acceptance Criteria

- Progress displays the saved practice position for every day and navigates to the right prompt.
- No score or completion is invented from a prompt index.
- Clear phone data requires confirmation and deletes onboarding/daily positions and current takes; a relaunch shows Welcome.
- Failed SQLite deletion preserves the prior progress state and exposes retry.
- Clear works offline and makes no backend request.
- Flutter tests and Android/iOS debug builds pass.

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

- Phone data deletion cannot revoke provider-side processing from earlier explicit requests. Public rollout needs a reviewed provider retention policy and account deletion flow if accounts are later added.
- Cache cleanup and SQLite deletion are separate operations. A cleanup failure must be reported, and reset must not claim total success.
- Local Xcode native builds are stalled by a host credential/toolchain issue; CI generic build can still verify iOS compilation.

## Decision Log

- 2026-10-02: Show saved practice positions as navigation state only. Provide explicit local deletion instead of suggesting a score or cloud data control.
- 2026-10-02: Clear both current recorder takes before the SQLite transaction. Keep the learner on Privacy with a retry message if either operation fails. Reset transient dialogue and pilot code before publishing the default session.
- 2026-10-02: Use a dedicated Progress route for all five daily positions, and keep the Home links short for limited-literacy navigation.

## Progress

- [x] Inspect existing progress/cache boundaries and blueprint screens.
- [x] Storage clear operation and reopen/failure tests.
- [x] Progress and Privacy screens.
- [x] Flutter format/analyze, 70-test suite plus a focused scaled-screen test, Android debug build and source checks.
- [x] Generic iOS CI build and final source quality record. Native simulator test remains blocked by local Xcode.
- [ ] Physical Android/iOS, live provider and educator review before pilot.
