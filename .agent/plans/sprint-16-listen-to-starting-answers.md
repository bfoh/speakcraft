# Sprint 16 — Listen to starting answers

## Goal

Let a learner hear their own starting-assessment recording before saving it and replay each saved answer during the current app session. This supports voice-first self-review without presenting an assessment result.

## Context

The seven-part starting assessment already records native `.m4a` takes and stages accepted answers in private temporary storage. The screen can read authored tasks aloud but cannot replay learner audio. The blueprint says learners should be able to hear progress; it also requires an explicit choice before retaining English Mirror recordings. This slice stays within the existing short-lived capture window and does not create English Mirror history.

## Non-goals

No score, transcript, proficiency claim, comparison with Day 5, persistent recording, cloud upload, background audio, new AI or backend endpoint. Do not expand the assessment's seven authored tasks.

## User Journey

The learner hears a task, records an answer, stops, then taps **Listen to my answer**. They can stop playback, record again, or save the take. After all seven answers, they see a list of task titles with a listen control for each staged recording. Leaving the assessment stops audio. Clearing recordings or phone data stops playback and removes the files. On next app launch, the staged recordings and replay list are gone.

## Technical Approach

- Add one small local-audio playback port with a native adapter using the maintained `audioplayers` package and absolute `DeviceFileSource` paths. Scope the player to one file at a time and release it on stop so it does not retain a deleted source.
- Add an assessment playback controller with visible loading, playing, idle and failure states. Use the existing assessment controller's in-memory item-to-path map for saved takes.
- Stop playback before recording, changing screens, clearing files or app interruption. Keep task TTS and learner playback from playing together.
- Wire the playback port through app services so widget tests can use a fake. Add no database column or remote data flow.

## Files / Components

`mobile/pubspec.yaml`, lockfile, `mobile/lib/core/audio/`, `mobile/lib/features/assessment/`, app services, Privacy screen, tests, architecture/privacy/readme and validation record.

## Data Model

No persistent data change. The existing assessment controller holds saved item paths in memory; native files remain in private temporary storage and are purged at launch or explicit clear. Playback state is transient.

## API Contract

No backend API change. Playback reads an existing local `.m4a` file and makes no network request.

## Privacy / Security

Only app-created private paths may reach the playback adapter. Stop and release the native player before deleting recordings. Do not log paths or audio content. The feature must not extend retention or imply that listening computes a result.

## Offline Behaviour

Replay works fully offline. A missing or evicted file produces a retry/clear message; it does not mark a capture as evaluated or upload data.

## Android / iOS Considerations

Use the shared Flutter implementation and native audio plugin on both platforms. Stop playback on lifecycle interruption and before opening the microphone. Verify Android and iOS builds. Hardware audio routes, calls and actual file playback still require the later physical-device session.

## Milestones

1. Add local playback port/adapter and controller tests for completion, failure, switching and stop.
2. Add current-take and saved-answer replay controls with clear loading/error states and widget tests.
3. Cover privacy clear, app lifecycle and source-file handling; update documentation.
4. Run the SpeakCraft quality gate, build Android/iOS, push and check CI.

## Acceptance Criteria

- A finished current take can be played and stopped before saving.
- A saved starting answer can be played from the completion screen during the same app session.
- Starting another recording, leaving, interruption, or clearing data stops playback before file removal.
- Missing files and playback errors show a useful message without advancing the assessment.
- Only one learner recording plays at a time; task audio is disabled while learner playback is active.
- Next launch still deletes staged answers; no replay history, score or network request is created.
- Formatting, static analysis, relevant tests and both platform builds pass, or a concrete blocker is documented.

## Validation

```sh
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

Run repository backend lint/type/tests and curriculum check as part of the quality gate. Review the pushed CI run.

## Risks / Unknowns

- Native audio-session handoff with the recorder and device TTS needs physical Android/iOS validation, including Bluetooth/wired audio and interruptions.
- iOS simulator native integration has previously been blocked by host log-reader permissions; source tests and builds do not prove actual playback.
- The provisional assessment picture and prompts still need educator review. No recorded answer is a measured learning outcome.

## Decision Log

- 2026-10-02: Use one local playback adapter for current and staged assessment takes. Keep files in the existing app-session cache; no English Mirror retention.
- 2026-10-02: Use `audioplayers` 6.8.1 for Android/iOS local file playback. Its documented `DeviceFileSource`, completion stream and stop/dispose methods cover this narrow need without custom platform channels.
- 2026-10-02: Add spoken guidance for replaying an answer. Playback stays an explicit learner action and does not change assessment outcomes or file retention.

## Progress

- [x] Read blueprint, instructions, existing assessment flow and relevant skills.
- [x] Implement local learner-answer playback.
- [x] Run the source quality gate and document results: 114 Flutter tests, 44 backend tests, curriculum check, Android APK and iOS simulator build pass. Physical playback acceptance remains pending.
- [ ] Confirm native playback and audio routing on physical Android and iOS devices when available.
