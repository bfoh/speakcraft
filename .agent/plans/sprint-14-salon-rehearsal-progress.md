# Sprint 14 — Saved AI Salon rehearsal progress

## Goal

Let a learner finish a Day-3 or Day-5 AI Salon rehearsal, review its authored goals, and see how many customer replies they completed on this phone after reopening the app.

## Context

The five-day Alpha includes Day-3 consultation and Day-5 customer-conversation scenarios. The app already supports explicit record, transcribe and send for these structured AI Salon exchanges. Dialogue is intentionally transient. Sprint 13 saves guided-practice attempts but does not cover salon application. The blueprint calls for practical progress, while an educator-reviewed success rubric and live provider validation are unavailable.

## Non-goals

No communication score, model-generated success flag, 90-second consultation claim, comparable Day-5 assessment, transcript/audio retention, remote analytics, new backend endpoint or changed AI prompt. The first general salon scenario remains unsaved.

## User Journey

The learner opens Day 3 or Day 5, enters its AI Salon scenario, listens to a customer, records an answer, reviews the tentative transcript and explicitly sends it. When the customer conversation ends, the screen shows the authored practice goals for self-review and saves the number of completed learner replies locally. Home and My practice show the best reply count for that day's scenario. A failed local write leaves the completed conversation visible with a retry action. The learner may practise again; a shorter later run does not erase their prior best count.

## Technical Approach

- Add a local per-scenario maximum learner-turn count to `LearnerProgress` and SQLite schema version 5. Migrate versions 1–4 without inferring salon progress.
- Save only when a Day-3/Day-5 conversation controller reaches its terminal state after successful provider replies. Never infer a result from opening the screen or microphone capture alone.
- Use `SessionController.update` for durable publication. On save failure, keep the dialogue and offer explicit retry. The `reset` path deletes summaries.
- Show current run and prior best as counts, with authored objectives to review. Keep success conditions out of scoring because the model has not validated them.

## Files / Components

`mobile/lib/core/storage/`, `mobile/lib/features/conversation/`, Home, My practice, router, tests and product/privacy/architecture documentation.

## Data Model

SQLite `salon_rehearsals(scenario_id TEXT PRIMARY KEY, best_turns INTEGER NOT NULL CHECK (best_turns BETWEEN 1 AND 6))`. IDs are authored scenario IDs. No transcript, audio, timestamp, identity or score is stored. Reset deletes the table.

## API Contract

No API changes. The existing explicit-send salon contract remains. All rehearsal summaries are local and are not uploaded.

## Privacy / Security

The locally stored count describes participation, not proficiency. No voice or words are persisted. The current dialogue remains transient and is cleared on leaving. A failed local save must not silently claim durable progress. Existing internal pilot authentication and provider retention limitations remain.

## Offline Behaviour

Saved counts are viewable offline. An ongoing AI Salon exchange still requires speech and salon backend access; connection failures preserve the current take for manual retry. The app must not substitute a scripted or fake AI response.

## Android / iOS Considerations

The same Flutter state and SQLite migration run on both platforms. Build both. Physical permissions, audio routes, interruptions and screen-reader review remain for the later device session.

## Milestones

1. Add immutable summary state, schema migration, reopen/reset/failure tests.
2. Save at the end of Day-3/Day-5 conversations and show goals, count and retry.
3. Show saved count on Home/My practice and verify widget journeys.
4. Run the SpeakCraft quality gate, document limits and push.

## Acceptance Criteria

- Merely opening or partially completing a salon scenario saves no new count.
- A terminal Day-3 or Day-5 conversation saves its actual number of learner replies, even if the provider ends early.
- Reopening the app retains the best completed count; a shorter run does not reduce it.
- Local write failure leaves the finished dialogue available and offers retry.
- Clear phone data removes the count.
- Learner-facing text never calls the count a success score or a timed consultation.
- Relevant automated tests, Android/iOS builds and CI pass or a concrete blocker is documented.

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

- A provider may end before the authored turn limit; save the actual count and label it clearly.
- Reply count does not prove customer needs were understood, nor that the Day-3 exchange lasted 90 seconds.
- Live provider quality and native device audio behavior remain unverified until credentials, consented samples and physical devices are available.

## Decision Log

- 2026-10-02: Save only the maximum number of completed learner replies for each Day-3/Day-5 scenario. An early provider ending is a shorter rehearsal, not a completed challenge.
- 2026-10-02: Use a fifth SQLite schema version so existing recorded guided-practice steps survive migration. Keep the first general salon scenario transient.
- 2026-10-02: Disable leave/restart while a local summary is writing, and keep the finished dialogue available if the write fails.

## Progress

- [x] Inspect blueprint, existing salon flow and SpeakCraft skills.
- [x] Implement local summary and learner UI.
- [x] Run formatting, analysis, 102 Flutter tests, 44 backend tests, Android APK and iOS simulator app builds; document the quality gate.
- [ ] Confirm the native salon summary on physical Android and iOS devices with the user's later device session.
