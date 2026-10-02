# Sprint 19 — Assessment and pilot review preparation

## Goal

Make the provisional starting and Day-5 prompts, rubric and pilot boundary concrete enough for Ghanaian educators and a language-assessment specialist to review without access to learner audio.

## Context

The app now has fixed Day-1 and Day-5 recording tasks, a research-derived rubric draft and no assessment result. It lacks local content approval, a consented sample protocol and public deployment controls. The current backend pilot code is for internal testing only.

## Non-goals

No recruitment, contact with reviewers, learner audio collection/export, scoring, public backend deployment, provider configuration or device testing.

## User Journey

A future reviewer receives an indexed content pack and records comments on task realism, wording, accessibility, fairness and comparability. A future facilitator can see the consent and handling decisions still required before any sample is collected. Learners continue to see only recording/self-review and self-reported readiness.

## Technical Approach

Add a reviewer pack with exact versioned prompt IDs and review fields; a rating worksheet template linked to the draft anchors; a pilot readiness gate with evidence and owners; and a dependency/operational risk list. Link these from the rubric and remaining-work tracker. Keep all templates local and free of learner data.

## Files / Components

`docs/ASSESSMENT_REVIEW_PACK.md`, `docs/ASSESSMENT_RATING_WORKSHEET.md`, `docs/PILOT_READINESS.md`, rubric, README and remaining-work tracker.

## Data Model

No application data model. The worksheet describes a prospective de-identified research row and keeps a separate consent record; it is not an implemented database or export format.

## API Contract

None.

## Privacy / Security

Content review uses no learner audio. A recorded sample may only be collected later under explicit, plain-language consent, specified access/storage/retention/withdrawal terms and an approved transfer method. The internal bearer code is insufficient for a public learner service.

## Offline Behaviour

These repository documents are reviewable offline. Current app behavior remains unchanged.

## Android / iOS Considerations

The review pack flags platform-specific prompt delivery, permission, playback, accessibility and audio-route evidence. Physical-device execution remains the final task.

## Milestones

1. Map each fixed prompt to the exact customer act and identify unsupported comparisons.
2. Create written content review and independent rating templates without learner data.
3. Document consent, provider, security and release gates.
4. Check links and repository quality; update the ExecPlan.

## Acceptance Criteria

- A reviewer can identify every authored prompt/version and record a decision or objection.
- The pack clearly separates content review, administration testing and independent sample rating.
- A worksheet keeps `NE` distinct from 0 and records actual help, prompt delivery and stimulus mode.
- The pilot gate lists specific evidence missing before scoring, audio collection or public access.
- No learner data is created, retained or transmitted by this sprint.

## Validation

`python3 scripts/sync_curriculum.py --check`; inspect prompt IDs against `curriculum/alpha.json`; `git diff --check`; run repository checks already required for the active Sprint 18 change. Review all links and mark external gates unresolved.

## Risks / Unknowns

The task wording and Day-1/Day-5 equivalence need local educator review. Consent, retention and provider contract details require owner decisions before implementation. A small feasibility sample cannot establish a reliable speaking scale.

## Decision Log

- 2026-10-02: Prepare content-only materials first. Do not add audio export or a scored result to create samples prematurely.

## Progress

- [x] Plan and inspect draft rubric, curriculum and pilot boundary.
- [x] Complete reviewer pack, worksheet and readiness gate.
- [x] Verify local links and update documentation.
- [x] Record external review and physical-device testing as open gates; devices are last.
