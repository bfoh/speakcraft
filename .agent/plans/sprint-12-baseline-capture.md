# Sprint 12 — Unscored baseline capture

## Goal

Let a learner complete the blueprint's five-part Day-1 baseline recording journey on Android and iOS. Capture responses for the current app session, without inventing an assessment result.

## Context

The onboarding screen currently says a full assessment is being prepared. The app already supports device speech, a native microphone, private temporary audio, local privacy reset and structured curriculum. The user has no educator-reviewed rubric or salon image. The blueprint specifies basic conversation, salon-image description, professional explanation, listening comprehension and several customer turns.

## Non-goals

No score, assessment result, pronunciation judgement, automatic transcription, AI role-play, server assessment endpoint, learner account, durable baseline or Day-5 comparison. No generated image will be described as educator-approved.

## User Journey

After onboarding or from Home, the learner opens Starting assessment. The app explains that recordings stay on this phone for the current app session and are cleared at next launch. The learner hears each short prompt, records an answer, and saves it before moving on. A generated salon scene supports the description task and is labelled as provisional. The listening task plays an authored customer request. The customer role-play has three authored turns. A final screen reports only that seven recordings were captured for this session; it gives no score and offers a clear action. The learner can leave and return during the same app session. A failed save leaves the current take available to retry.

## Technical Approach

- Add validated assessment tasks to canonical `curriculum/alpha.json`, including three authored role-play turns. Keep each item short and identified by a stable ID.
- Generate one provisional salon scene, package it as a Flutter asset and provide a text alternative. The learner-facing screen and docs say that the visual needs educator review.
- Use a dedicated native microphone and private cache folder for baseline takes. Copy each completed take atomically into one slot per item. Clear old slots on app startup and via Privacy. Never upload automatically.
- A feature controller tracks captured slots and current position in memory. Publish progress only after a successful file copy and recorder cleanup. Preserve a failed take for retry. A new attempt replaces its previous slot.
- Add an optional onboarding entry and Home link. Use large labelled controls, an audio instruction, permission/failure states and visible task progress.

## Files / Components

Canonical curriculum and synchronized assets, curriculum validators and tests, provisional salon image asset, assessment capture store/controller/screen, app service composition and route, onboarding/Home/Privacy copy, widget/native tests and docs.

## Data Model

No new durable database table. Captured `.m4a` files live only in the app's private temporary directory, keyed by authored task ID. The cache is deleted on the next app bootstrap and by Clear phone data. The current task and captured IDs live in memory. This does not establish a durable baseline for later score comparison.

## API Contract

No new endpoint or network payload. No assessment recording is sent to the backend in this slice.

## Privacy / Security

The onboarding/assessment UI explains temporary local audio before recording. Files use app-private storage and a fixed authored ID allowlist; never use learner text as a path. Saves use a temporary file plus rename. Old files are purged at startup. Clear phone data also removes assessment takes. No transcript, identifier, secret or score is added.

## Offline Behaviour

All capture steps work without internet. Device playback may fail if no English voice is installed; visible words remain. Failed local writes keep the learner on the same task and offer retry.

## Android / iOS Considerations

Reuse the native microphone permission/interruption handling on both platforms. Confirm both debug builds, then use simulator/emulator journeys where available; physical permission, audio route, TTS quality and accessibility checks remain for the user's later device session.

## Milestones

1. Author and validate the seven capture items and provisionally generated visual.
2. Add private cache and a tested session controller.
3. Add the learner flow and navigation/privacy integration.
4. Run quality checks and update the plan and validation documentation.

## Acceptance Criteria

- The learner can reach all five blueprint parts, including three separate customer replies.
- Each part offers audible and visible guidance, a clear microphone state and a retry path.
- The next part unlocks only after the current recording is safely staged; failed staging preserves the take.
- Leaving and returning in the same app session preserves the position and captures.
- Relaunch and confirmed Clear phone data remove all staged assessment audio.
- The UI shows no score, confidence rating, pronunciation judgement or claim of a comparable baseline.
- Android and iOS build, and automated tests cover content, storage failure, navigation and privacy cleanup.

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
```

## Risks / Unknowns

- The provisional visual and authored prompts need Ghanaian educator review. They are not a validated assessment instrument.
- Session-only audio cannot be used for a later Day-5 comparison. Durable assessment requires a reviewed retention, consent, scoring and authentication design.
- The local iOS simulator journey stalled in Sprint 11. Platform compilation is separate from native behavior checks.

## Decision Log

- 2026-10-02: User has no reviewed rubric or salon image. Build an unscored, temporary capture journey with an explicitly provisional generated scene. Do not claim baseline measurement.
- 2026-10-02: Keep seven responses in separate app-private temporary files and hold task position only in memory. Purge staged files before database and microphone bootstrap so even a later initialization failure cannot preserve the previous session.
- 2026-10-02: Use fixed authored customer lines for the three role-play turns. The listening prompt is visible as an accessibility alternative; no listening score is inferred.
- 2026-10-02: Native iOS test initially reached the OS microphone prompt. After a simulator-only permission grant, the full native journey passed with a nonempty staged baseline file.

## Progress

- [x] Read blueprint, repository instructions and relevant skills.
- [x] Author and validate seven capture items and a provisional generated visual.
- [x] Implement private cache, startup purge and session controller.
- [x] Implement screens, navigation and privacy behavior.
- [x] Flutter tests, format and analysis; backend checks; Android and iOS builds; native iOS journey.
- [x] Apply the SpeakCraft quality gate and document pilot blockers.
- [ ] Educator review and physical Android/iOS checks before a learner pilot.
