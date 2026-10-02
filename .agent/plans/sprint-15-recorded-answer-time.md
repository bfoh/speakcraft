# Sprint 15 — Recorded answer time in AI Salon

## Goal

Help learners see how long they recorded answers during a completed Day-3 or Day-5 customer rehearsal, alongside the existing completed-reply count. Preserve the longest total on this phone so learners can review their practice.

## Context

The blueprint's Day-3 scenario includes a 90-second consultation goal. The current app records bounded takes and saves only completed customer-reply counts. It cannot measure the full consultation or judge communication quality. This slice measures microphone recording time for replies that the learner explicitly sends and the backend accepts.

## Non-goals

No claim that a 90-second consultation is complete, speech-activity detection, scoring, rubric, transcript or audio retention, backend analytics, OpenAI work or Day-5 assessment result.

## User Journey

The learner records and sends each customer answer. At the end of a Day-3 or Day-5 exchange, the learner sees the number of completed replies and the total time spent recording those answers. The app saves the longest such total locally. A failed upload does not add time; a failed local save offers retry. The learner can view the saved summary offline and clear it with phone data.

## Technical Approach

- Measure elapsed capture time with a monotonic stopwatch from successful native start until stop is requested; exclude encoding, transcription and network wait. Clear the measure on discard and failure.
- Pass the completed take's duration to the conversation controller. Add it only after a successful provider response; reset with the conversation and ignore stale results.
- Extend the local salon summary with an independent longest recorded-answer total. Save only on a terminal authored Day-3/Day-5 rehearsal. Show the current run and local best with explicit labels.
- Keep the existing explicit-send flow and best completed-reply count.

## Files / Components

`mobile/lib/features/lesson/microphone_controller.dart`, `mobile/lib/features/conversation/`, `mobile/lib/core/storage/`, Home, My practice, mobile tests, architecture/privacy/product documentation.

## Data Model

SQLite schema version 6 adds `longest_recorded_seconds INTEGER NOT NULL DEFAULT 0` to `salon_rehearsals`. It stores a whole-second local maximum for each authored scenario. The maximum reply count and maximum answer time may come from different rehearsals and are labeled independently. Version-5 migration initializes time to zero without inferring it. No recordings, transcripts or conversation turns are retained in this table.

## API Contract

No endpoint or payload changes. Measurement remains local and is never sent to the backend.

## Privacy / Security

Recorded time is practice-history metadata, not a proficiency measurement. Preserve existing explicit-send and local-clear behavior. Persist only the duration summary and reply count; never log audio paths, words or tokens.

## Offline Behaviour

Saved summaries remain readable offline. Recording can continue without connectivity; the conversation requires the existing backend, and a failed send keeps the take available without counting it. A failed local write keeps the finished rehearsal available for retry.

## Android / iOS Considerations

Use the shared Flutter controller and SQLite migration. Verify builds for both platforms. Native microphone interruptions end a take at interruption; physical permission and audio-route checks remain for the later device session.

## Milestones

1. Add and test monotonic microphone duration and successful-send accumulation.
2. Add SQLite version-6 summary and migration/reopen/reset tests.
3. Show current and saved answer time in accessible salon and progress UI.
4. Run quality checks, document limits and push.

## Acceptance Criteria

- Time starts only after a successful native recording start and stops before native stop processing.
- Failed, discarded, replaced and unsent takes add no conversation time; provider retry adds a take once.
- Completed Day-3/Day-5 exchanges save the longest total recorded-answer seconds and best reply count independently.
- Version-5 data migrates without losing counts, and phone-data reset removes recorded-time summaries.
- UI labels recorded-answer time without claiming speech duration, consultation duration or success.
- Formatting, analysis, relevant tests and Android/iOS builds pass, or blockers are documented.

## Validation

```sh
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Run configured backend lint/tests as the repository quality gate requires; check CI after push.

## Risks / Unknowns

Elapsed recording time may include silence, so it cannot prove active speech. It excludes the customer's turns and all waiting time. A 90-second consultation remains unverified until the full scenario is measured and an educator-approved rubric exists. Native physical-device behavior remains unverified until devices are connected.

## Decision Log

- 2026-10-02: Measure only successful explicitly sent answer takes. Use a monotonic clock to avoid wall-clock changes.
- 2026-10-02: Keep time and reply maxima independent and describe them as local practice summaries.

## Progress

- [x] Inspect the existing flow, blueprint and SpeakCraft skills.
- [x] Implement and verify recorded-answer summaries.
- [x] Run formatting, analysis, 107 Flutter tests, 44 backend tests, Android/iOS simulator builds and the quality gate; document results.
- [ ] Confirm native capture and display on physical Android and iOS devices when available.
