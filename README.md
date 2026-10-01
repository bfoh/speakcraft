# SpeakCraft

**Real English for Real Skills.** A voice-first English practice app for Ghanaian TVET learners in Beauty & Cosmetology.

## Sprint 1

Welcome → Profession → Support Language → Meet Kora → Assessment Introduction → Home → Day 1: This Is Me → local microphone practice.

Sprint 1 established shared Android/iOS screens, a small accessible design system, saved onboarding and phrase position, authored audio instructions through device speech, and real local recording. The assessment, scoring, generated Kora conversations and lesson completion remain unavailable. Days 2–5 are structured curriculum seeds and are unavailable in the UI.

The app works without the backend. Routine recordings stay in private cache for the running session, and are removed on replacement, deletion, phrase change or next launch. Installed device voices determine whether audio instructions work offline.

## Sprint 2 speech slice

Day 1 includes an explicit **Hear my words** action when a SpeakCraft API URL is configured. It uploads the current take for transcription, displays what speech recognition heard, and lets the learner listen or retry. It does not score, correct or assess the learner. Offline recording and local phrase progress continue to work. The OpenAI key is server-only; live provider transcription remains unverified until a key is supplied outside the repository. See the [Sprint 2 plan](.agent/plans/sprint-02-speech-recognition.md).

## Sprint 3 teaching slice

After reviewing a transcript, the learner may choose **Help me say it better**. Kora gives one short teaching response tied to the selected curriculum prompt, with an example to hear and repeat when useful. The learner can retry recording. The app displays no score or pronunciation judgement. Feedback requires the same internal backend and pilot access code as transcription. A failed request keeps the local take and transcript; generated feedback is not saved. Model quality remains unverified without a server key and educator review. See the [Sprint 3 plan](.agent/plans/sprint-03-teaching-feedback.md).

## Sprint 4 conversation slice

Day 1 also offers **Talk with Kora**: a short spoken exchange about the learner's introduction. Kora starts with an authored question. The learner records, reviews the tentative transcript and explicitly sends each reply. Kora responds within the Day-1 goal, with a limit of three learner turns. The app reads Kora's words aloud through the device voice and keeps the current take if a request fails. The dialogue is transient and has no score. This completed-file exchange is slower than live streaming and still needs real learner review. See the [Sprint 4 plan](.agent/plans/sprint-04-kora-conversation.md).

## Repository

```text
mobile/       Flutter app, Android/iOS runners, unit/widget/device tests
backend/      FastAPI factory, typed health API, configuration and tests
curriculum/   Canonical five-day Alpha content
scripts/      Curriculum validation and asset packaging
.agent/       Execution plans and planning requirements
.codex/skills/ SpeakCraft mobile, Kora and quality guidance
database/     Future server migrations; current local schema is in mobile/core
tests/        Test-location guide
docs/         Blueprint, architecture, pedagogy, privacy and validation record
.github/      Automated checks and platform build jobs
```

Read [AGENTS.md](AGENTS.md), the [blueprint](docs/PRODUCT_BLUEPRINT.docx), and [Sprint 1 plan](.agent/plans/sprint-01-foundation.md) before significant changes.

## Prerequisites

- Flutter **3.47.5** (Dart **3.13.4**), pinned in `.flutter-version`.
- Android: Java 17, Android SDK platform/build-tools 36, emulator or USB device, accepted SDK licenses. Minimum device API 24.
- iOS: macOS, Xcode with iOS simulator runtime, CocoaPods. Minimum device iOS 15. A physical iPhone needs your own development team/signing settings.
- Backend: Python 3.12 and pip.

Check the installed toolchain with `flutter doctor -v` and available targets with `flutter devices`.

On the machine where Sprint 1 was prepared, Flutter is installed outside the repository. Add it to the current shell:

```sh
export PATH="$HOME/.local/share/speakcraft/flutter/bin:$PATH"
```

The local Flutter configuration points to the Java/Android tools under `$HOME/.local/share/speakcraft/`. Other machines should use their own installed SDK paths.

## Run the mobile application

From this repository:

```sh
python3 scripts/sync_curriculum.py --check
cd mobile
flutter pub get --enforce-lockfile
flutter devices
flutter run -d <device-id>
```

To connect a local backend for speech on the iOS simulator, use `flutter run -d <device-id> --dart-define=SPEAKCRAFT_API_BASE_URL=http://127.0.0.1:8000`. For an Android emulator, use `http://10.0.2.2:8000`. The URL contains no secret. A facilitator enters the pilot access code in the app when sending a recording; it stays only in memory. For physical devices, use an HTTPS backend URL. Local recording remains available when no URL is configured.

Replace `<device-id>` with an Android or iOS device from `flutter devices`. For an iOS simulator, start Simulator with `open -a Simulator` first. For Android, start an installed emulator or connect an authorized USB device. The same Dart entry point runs on both. No environment secrets or backend URL are needed.

Build development artefacts:

```sh
cd mobile
flutter build apk --debug
flutter build ios --simulator --debug
```

Release signing/store distribution is not configured. Do not use a debug signing key for a published release.

## Run the backend

From the repository root, create a virtual environment with Python 3.12:

```sh
cd backend
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.lock
.venv/bin/python -m pip install --no-deps -e .
SPEAKCRAFT_DOCS_ENABLED=true .venv/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

The speech, feedback and Kora dialogue endpoints are disabled until `OPENAI_API_KEY` and a long random `SPEAKCRAFT_PILOT_TOKEN` are exported in the backend environment. Keep both out of Git and logs. `SPEAKCRAFT_FEEDBACK_MODEL` may override the server-side text model. This shared-token setup is for local/internal testing only; public exposure needs learner authentication and abuse controls. The service does not save uploaded audio, transcripts, feedback or dialogue.

If `.venv` already exists (as on the Sprint 1 development machine), the last command starts the backend directly. `.env.example` documents the optional setting; environment files are not loaded implicitly.

```sh
curl http://127.0.0.1:8000/health
```

Expected response: `{"status":"ok","service":"speakcraft-api","version":"0.1.0"}`.

When enabled, [interactive API docs](http://127.0.0.1:8000/docs) describe health, transcription, prompt-bound teaching feedback and the bounded Kora dialogue endpoint. Formal assessment, scoring and learner-data endpoints remain unimplemented. Health means the process is alive, not that speech credentials are configured.

## Validate

From the repository root:

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
```

Native smoke test (disposable emulator/simulator, microphone permission granted):

```sh
cd mobile
flutter test integration_test/foundation_test.dart -d <device-id>
```

The native smoke test uses real SQLite and recording, a separate test database, and a local test HTTP server for speech, feedback and conversation contracts. It does not call OpenAI or establish teaching quality. See the [Sprint 1](docs/SPRINT_1_VALIDATION.md), [Sprint 2](docs/SPRINT_2_VALIDATION.md), [Sprint 3](docs/SPRINT_3_VALIDATION.md) and [Sprint 4](docs/SPRINT_4_VALIDATION.md) validation records.

## Next build milestone

Build the first structured AI Salon customer scenario, with authored goals and success conditions. Verify transcription, teaching and dialogue with consented Ghanaian-accented speech and educator review before a learner pilot.
