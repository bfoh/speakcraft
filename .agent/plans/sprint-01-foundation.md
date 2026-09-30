# Sprint 1 — SpeakCraft Alpha foundation

## Goal

Deliver a runnable Android and iOS Flutter foundation and the Day-1 entry journey. Establish a minimal FastAPI service, a human-authored five-day curriculum, and repeatable checks. Complete Sprint 1 only.

## Context

The repository starts with engineering guidance, skills, and the Product & Technical Blueprint, but no application code. Read AGENTS.md, all three SpeakCraft skills, .agent/PLANS.md, and the complete blueprint (including the visual concept). Blueprint sections 11, 15, 18–20, 26–27, and 31 govern this sprint.

The current user instruction takes precedence over the blueprint section 35 suggestion to build a complete customer/transcription slice. This sprint implements the section 31 cross-platform foundation, with assessment introduction only and no computed learning results.

## Non-goals

No OpenAI integration, transcription, evaluation, generated Kora conversation, baseline assessment execution, authentication, cloud persistence, sync service, payments, or implementation of Days 2–5. No elaborate branding or animations. No fabricated scores or lesson completion.

## User Journey

Welcome → select Beauty & Cosmetology → choose English support (other languages await native-speaker review) → meet Kora, identified as an AI tutor → assessment introduction with honest availability notice → Home → Day 1: This Is Me → listen to example phrases → microphone permission → record → stop → recording confirmation or retry. A learner can return Home and resume the current phrase without losing it. The first successful recording is not a completed lesson or assessment.

## Technical Approach

- Flutter with feature-oriented app/core/features/shared directories; Riverpod for dependencies and state; GoRouter for routes and onboarding guards.
- Material design tokens and a small set of labelled, large reusable buttons, cards, audio controls, and responsive page layouts.
- Bundled, versioned JSON curriculum, loaded through a typed repository. A packaging script copies the canonical curriculum into mobile assets and checks for drift.
- SQLite for onboarding choices and Day-1 position, written before confirming/navigation. Use a repository interface with test-only in-memory doubles. No server database or speculative migrations; SQLite schema version 1 is the first local migration.
- Microphone interface isolated from plugin and UI, with explicit idle/requestingPermission/ready/recording/processing/success/failure/permissionDenied states. The native adapter uses the record package. Serialise transitions; bound recording duration; stop on background/navigation; never auto-resume recording.
- Routine audio stays in the app cache, one attempt at a time, and is removed on discard/replacement/next launch. Navigation within the running app preserves the latest take. No audio upload, transcription, score, or raw-audio analytics.
- Device text-to-speech reads fixed instructional text and example phrases. Availability depends on installed device voices; visible text and a useful failure message remain available. No generated AI voice.
- FastAPI application factory, typed health response, settings from environment, focused tests, and no speculative endpoints. Mobile does not require the backend in this sprint.

## Files / Components

```text
mobile/lib/app/                 app, providers, router, theme
mobile/lib/core/                curriculum, local persistence, audio
mobile/lib/features/onboarding/ learner setup and assessment introduction
mobile/lib/features/home/       current lesson entry
mobile/lib/features/lesson/     Day-1 phrases and microphone controller/UI
mobile/lib/shared/              reusable accessible components
mobile/test/                   controller, persistence, curriculum, widget tests
mobile/integration_test/       device smoke journey
mobile/android/ + ios/         native runners and permission declarations
backend/app/                   settings, application factory, health API
backend/tests/                 API/settings tests
curriculum/                    canonical five-day JSON and validation
scripts/                       curriculum packaging and checks
.github/workflows/             mobile/backend checks and platform builds
docs/                          architecture, principles, pedagogy, privacy, decisions
```

## Data Model

Curriculum: schema_version, course id/version/profession, five ordered lessons with stable IDs, objectives, duration, target language, and structured prompts. Days 2–5 carry human-authored objectives and example language but remain unavailable in this build.

Local learner settings: profession, support language, onboarding step/completed flag. Local lesson progress: lesson ID and phrase index only. Never infer mastery, completion, or confidence from visiting a screen. Audio is ephemeral cache data, not a learning-history record.

## API Contract

GET /health → 200 JSON {"status":"ok","service":"speakcraft-api","version":"0.1.0"}. OpenAPI schema at /openapi.json and interactive documentation at /docs are available only when `SPEAKCRAFT_DOCS_ENABLED=true`; they are off by default. All future speech routes remain unimplemented and return 404. No database dependency for health.

## Privacy / Security

Request microphone permission only after the learner presses the microphone control and sees recording purpose. No background recording. Store routine audio in private cache and delete at next launch or explicit discard/replacement. Do not log learner content. Exclude local environment files, native build output, credentials, and signing files from Git. No mobile API secrets. No public-launch authentication or cloud data collection in Sprint 1. Explain local reset and backup behavior in privacy documentation.

## Offline Behaviour

All navigation, packaged curriculum, local settings, lesson position, and recording work without the backend. Device TTS may need a downloaded voice; expose failure without blocking practice. Do not invent connectivity state or promise sync. Writes must succeed before UI confirms saved progress; storage failure keeps the current screen with a retry message.

## Android / iOS Considerations

Generate both native targets from the same Flutter version. Android declares RECORD_AUDIO and uses runtime permission through the recorder; disable app data backup for sensitive local content. iOS declares NSMicrophoneUsageDescription and has no background-audio capability. Stop capture on lifecycle interruption and route departure on both platforms. Inspect deployment minimums required by plugins. Physical microphone, permission denial/revocation, interruptions, Bluetooth/wired routing, and screen-reader checks need both device platforms.

## Accessibility

Minimum 48–56 logical pixel targets; semantic labels and live recording state; icons with text; high contrast; scrollable constrained layouts; text scaling and small screens; listen controls for instructions; no colour-only status or automatic microphone start. Do not claim a device voice models a Ghanaian accent. Support language remains English until reviewed translations exist.

## Milestones

1. Record plan and establish toolchain, native runners, repository hygiene, and dependency locks.
2. Add structured curriculum, persistence, design primitives, and complete entry navigation.
3. Implement provider-independent microphone controller/native adapter, failure handling, and local audio instructions.
4. Add minimal backend, meaningful automated tests, and CI.
5. Run quality gates, build Android/iOS where tools permit, inspect UI, update docs and this plan with evidence.

## Acceptance Criteria

- Both native runner projects exist and compile with supported tools, or an exact toolchain blocker is documented without declaring that platform verified.
- The complete requested entry journey is navigable; returning learners resume Home and saved Day-1 phrase position.
- A learner sees recording purpose, requests permission, explicitly starts/stops capture, and receives truthful success/failure feedback.
- Permission denial, recorder failure, repeated taps, lifecycle interruption, and local-save failure have tested handling.
- Navigation and curriculum need no network; local storage survives app restart.
- Five Alpha day titles/objectives match the blueprint, outside widget source.
- No mocked production AI, invented results, cloud uploads, or client secrets.
- Formatting, static analysis, unit/widget/API tests pass; platform/device gaps are explicitly reported.

## Validation

From repository root (Flutter on PATH; Python 3.12):

```sh
python3 scripts/sync_curriculum.py --check
cd mobile
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
flutter test integration_test -d <device-id>
cd ../backend
python3 -m venv .venv
.venv/bin/python -m pip install -e '.[dev]'
.venv/bin/ruff format --check .
.venv/bin/ruff check .
.venv/bin/mypy app
.venv/bin/pytest
cd ..
git diff --check
```

Manual device checklist: onboarding and back navigation, 320px and large text, VoiceOver/TalkBack, airplane mode, permission deny/allow/revoke, interrupted recording, return to lesson, relaunch/resume, audio route changes, discard take. Record actual outcomes, not assumptions.

## Risks / Unknowns

- Flutter 3.47.5, Java 17 and Android SDK 36 were installed outside the repository; Xcode 16.3 and an iOS 18.4 simulator are available. Android/iOS debug builds and the iOS native microphone journey pass. Android microphone/device behavior remains unverified until a device or emulator is available.
- Language support beyond English is not validated; no unreviewed translations will be presented.
- Fixed examples are editorial implementation content aligned to blueprint objectives; educator and target-learner review remains necessary.
- Device TTS and Bluetooth behavior require device verification. App signing/store publication are outside scope.
- `flutter_tts` builds with the pinned Flutter version but emits compatibility warnings for a future Kotlin Gradle Plugin migration and iOS Swift Package Manager support; revisit before upgrading Flutter.

## Decision Log

- 2026-09-29: Follow the explicit Sprint 1 scope over blueprint section 35 full AI slice; preserve the five-day curriculum from section 11, not the thirty-day sequence.
- 2026-09-29: Use Riverpod and GoRouter as recommended. Use sqflite directly rather than Drift/code generation for two small local records.
- 2026-09-29: Implement real local capture, with no AI integration or fabricated feedback; assessment is an introduction only.
- 2026-09-29: Keep repository work on the current checkout. The user's earlier request to push SpeakCraft to the named GitHub repository authorizes publishing the completed Sprint 1 work after quality checks.
- 2026-09-30: Keep `/docs` and `/openapi.json` disabled by default; enable explicitly for local backend development.
- 2026-09-30: Add scoped Riverpod dependencies and a production-bootstrap test after the first iOS app launch exposed an initialization error missed by widget-only tests.
- 2026-09-30: Validate real iOS simulator recording and local SQLite through a native integration test. Android build validation passes; record Android device testing as a pilot prerequisite.

## Progress

- [x] Read guidance, blueprint, skills, and inspect repository.
- [x] Write ExecPlan before application code.
- [x] Toolchain and project foundation.
- [x] Curriculum, persistence, design, onboarding, Home, Day 1.
- [x] Microphone abstraction and native integration.
- [x] Backend, tests, and CI.
- [x] Quality gate, platform validation, documentation, final report. See `docs/SPRINT_1_VALIDATION.md` for executed checks and device limitations.
