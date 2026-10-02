# Sprint 10 — Offline My Words review

## Goal

Help learners revisit useful Beauty & Cosmetology words and phrases, with a simple review schedule driven by their own indication that a phrase needs more practice or felt easy.

## Context

The blueprint lists My Words / Review and offline vocabulary review as Alpha capabilities. Five days of authored target language already exist in `curriculum/alpha.json`. The mobile app stores local onboarding and practice positions in SQLite and reads examples through the device voice.

## Non-goals

No generated vocabulary, automated mastery score, speech correctness judgement, cloud sync, personal phrase bank, AI feedback, new backend endpoint or fixed 60/25/15 lesson mix. A learner's button choice is a self-report, not a measured language result.

## User Journey

From Home, the learner opens My Words. The app shows due authored phrases and allows the learner to hear one, say it aloud, then mark More practice or Felt easy. More practice brings it back soon; Felt easy schedules it later. The learner can review all items even when none are due. The screen explains that these choices schedule practice and are not a score. All actions work without internet. Clearing phone data also erases this review history.

## Technical Approach

- Define stable review IDs in canonical curriculum data, using a bounded set of phrases from the five-day pathway, with a short usage cue.
- Validate the review items in both runtime curriculum parsers and synchronise byte-identical assets.
- Add a local SQLite `review_state` table in schema version 3, with migration from versions 1/2. Store attempts, a small self-rated ease stage, last reviewed time and next review time. Do not store recordings or transcripts.
- Expose a repository interface and controller for due/all lists and explicit rating. Save before publishing state. Use a deterministic scheduler with injected time for tests.
- Add a feature-oriented screen with large controls, text plus audio and clear offline/no-due states. Link from Home. Extend confirmed local erasure to the new table.

## Files / Components

`curriculum/alpha.json`, asset copies, curriculum validators, Flutter storage/controller/screen/router/Home, privacy reset, tests and docs. Backend only changes if its curriculum validator needs the new authored data shape; no API service changes.

## Data Model

`review_state(item_id TEXT PRIMARY KEY, attempts INTEGER, ease_stage INTEGER, last_reviewed_at INTEGER, next_review_at INTEGER)`. Item IDs are authored and stable. The table is local. No audio or transcript is retained. Migration preserves existing onboarding and positions.

## API Contract

No new endpoint or payload. Review is fully offline.

## Privacy / Security

Only self-rated review metadata is stored. Use parameterised SQLite operations and a whitelist of authored item IDs. Confirmed Clear phone data deletes this table in the same transaction as other local progress. No network or provider call.

## Offline Behaviour

Every review action works offline; device text-to-speech depends on installed voice support. Failed local writes keep the previous visible schedule and show retry.

## Android / iOS Considerations

Use shared Flutter UI and the existing device speech abstraction. Verify migration and reset through host SQLite tests, build both targets, then check native audio and accessibility with connected devices later.

## Milestones

1. Author and validate a small review deck.
2. Implement scheduler, schema migration and repository tests.
3. Add My Words UI and navigation with offline/error states.
4. Run quality checks and update the plan, privacy/architecture docs and validation record.

## Acceptance Criteria

- Learner sees due phrases and can hear them on either platform where a device voice is installed.
- Each explicit self-rating updates the local schedule after a successful write; a failed write reports retry.
- Relaunch preserves review state, and old schema data migrates without loss.
- Learner can open all authored phrases even when none are due.
- Review does not display a score or claim speech accuracy.
- Clear phone data also removes review history.

## Validation

```sh
python3 scripts/sync_curriculum.py --check
cd mobile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

## Risks / Unknowns

- A self-rated schedule is a useful starting point, not evidence of vocabulary retention. Educator and learner review should tune intervals and content.
- Local Xcode simulator builds are currently blocked by a host credential/toolchain issue; generic iOS CI can check compilation.
- Review metadata is local and can be lost if the phone is reset. No account or sync exists.

## Decision Log

- 2026-10-02: Start with an authored, offline deck and transparent self-rating. Avoid claiming inferred weakness or mastery without assessment evidence.
- 2026-10-02: Schedule More practice after four hours and repeated Felt easy choices after one, three and seven days. Keep these intervals deterministic and testable until pilot evidence suggests changes.
- 2026-10-02: Migrate SQLite to version 3 for local review state. The existing confirmed phone reset deletes review state in the same transaction as onboarding and daily positions.
- 2026-10-02: Wait for an in-flight review write before confirmed local deletion so it cannot recreate a review row afterward.

## Progress

- [x] Inspect blueprint and existing curriculum/storage boundaries.
- [x] Author and validate review items.
- [x] Add persistence, scheduler and version 1/2 migration tests.
- [x] Add UI and widget tests, including empty due list, write retry and large text.
- [x] Backend checks, mobile format/analyze, full 81-test suite, wheel asset packaging and Android debug build.
- [~] Generic iOS CI build and final source quality record. Native simulator test remains blocked by local Xcode.
- [ ] Educator review, physical devices and live provider verification before pilot.
