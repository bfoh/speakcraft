# SpeakCraft Execution Plans

For significant features, architecture changes, migrations or multi-step
implementation work, create an ExecPlan in:

.agent/plans/<feature-name>.md

An ExecPlan must be understandable by an engineer who has the repository but
no previous conversation context.

Every ExecPlan must contain:

## Goal

What user or product outcome are we delivering?

## Context

Which parts of SpeakCraft are involved?

## Non-goals

What are we deliberately not building?

## User Journey

Describe the experience from the learner's perspective.

## Technical Approach

Explain the proposed implementation.

## Files / Components

Identify expected areas of the repository that will change.

## Data Model

Document new or modified persistent data.

## API Contract

Document new or changed endpoints and payloads.

## Privacy / Security

Identify sensitive information, permissions, authentication and data-retention
implications.

## Offline Behaviour

Explain behaviour when connectivity is unavailable or interrupted.

## Android / iOS Considerations

Explicitly identify platform implications.

## Milestones

Break work into small independently verifiable stages.

## Acceptance Criteria

Use observable outcomes.

Example:

- learner can record a speaking attempt;
- recording survives temporary UI navigation;
- learner receives transcription;
- failed network request produces a useful message;
- Android microphone permission works;
- iOS microphone permission works.

## Validation

List exact commands/tests/checks that prove the implementation works.

## Risks / Unknowns

Record unresolved technical or product questions.

## Decision Log

Record important decisions made during implementation.

## Progress

Maintain:

- [ ] planned
- [~] in progress
- [x] complete

Never continue past a failed critical validation step without fixing or
explicitly documenting the blocker.
