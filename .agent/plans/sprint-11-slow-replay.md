# Sprint 11 — Slower spoken examples

## Goal

Let learners hear key example phrases at a slower pace on either mobile platform, using the same device speech already available in SpeakCraft.

## Context

The five-day lessons, My Words, Help Me Say It, and Kora/customer turns display text and offer a normal-speed device voice. Some learners need another listen before speaking. The shared audio component owns playback and stop behavior.

## Non-goals

No recorded voice library, pronunciation score, accent judgement, AI speech generation, voice preference setting, backend endpoint, or new persistent learner state.

## User Journey

The learner reads or hears an example. They can tap **Listen slowly** to hear the same words at a gentler device speech rate, stop it, and try speaking. Normal and slow playback cannot run at the same time within one phrase control. Text remains available if the device voice fails.

## Technical Approach

Add a `slow` option to the existing `SpeechOutput` interface and implement it with two device speech rates. Extend the shared audio button with an optional second control and one playback state. Expose slow replay on examples and conversational phrases, preserving the existing enabled/recording rules. Keep instruction-only audio compact.

## Files / Components

`mobile/lib/core/audio/speech_output.dart`, `mobile/lib/shared/components.dart`, lesson, review, Help Me Say It and conversation screens, mobile fakes/tests, README and validation notes.

## Data Model

None. Playback speed is transient UI state and is not saved.

## API Contract

No network API change. The local `SpeechOutput.speak` method accepts an optional slow flag; its default remains normal playback.

## Privacy / Security

The device speech engine reads the same visible text. This feature adds no upload, credential or retained data. Learner transcripts already visible in the UI are not given slow replay by default.

## Offline Behaviour

Both playback speeds use the installed device English voice. When that voice is unavailable, visible text and a learner-friendly error remain. No connectivity is required by SpeakCraft for this feature.

## Android / iOS Considerations

Use the shared `flutter_tts` adapter on both platforms. Check compilation for both, then check playback in the iOS simulator. Final sound quality, voice availability and audio routing must be checked on connected Android and iOS devices later.

## Milestones

1. Add the speech contract and coordinated slow replay control.
2. Expose it on the relevant learner phrases and add focused tests.
3. Run mobile formatting, analysis, tests and platform builds; update documentation and the quality gate.

## Acceptance Criteria

- Key lesson examples, My Words phrases, Help Me Say It phrases and Kora/customer turns offer **Listen slowly**.
- The slow control calls the device speech adapter with the slower rate; normal playback keeps its current rate.
- A phrase can be stopped and does not continue after its control is removed.
- Controls remain large, labelled, and unavailable when their existing microphone interaction disables audio.
- Voice failure shows a useful message and leaves the words visible.

## Validation

```sh
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
flutter test integration_test/foundation_test.dart -d BB727569-6977-4D3D-92E4-859BE36760BA
```

## Risks / Unknowns

- Installed TTS voices and speech-rate interpretation vary by device. Physical Android and iOS listening checks remain for the user's later device session.
- A device voice is an aid to listening, not a pronunciation standard for Ghanaian English.

## Decision Log

- 2026-10-02: Use an optional slow control on the shared audio component. This keeps one playback state per phrase and avoids a new dependency or audio service.
- 2026-10-02: Use 0.3 for slow playback and retain 0.4 for normal playback through `flutter_tts`. Do not treat either device voice as a pronunciation score or accent standard.
- 2026-10-02: The native test runner built but CoreSimulator stalled after launch and again during restart/device discovery. Keep the native journey open for the user's later device session; record compilation separately from journey execution.

## Progress

- [x] planned
- [x] speech contract and UI implementation
- [x] Flutter formatting, analysis and 84 unit/widget tests
- [x] Android debug and iOS simulator app builds
- [x] Backend regression checks, security review and documentation
- [x] Backend, mobile/Android and iOS CI jobs on the implementation commit
- [ ] Native iOS journey and Android/iOS listening check (CoreSimulator stalled; physical devices later)
