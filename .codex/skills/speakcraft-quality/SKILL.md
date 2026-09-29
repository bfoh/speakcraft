---
name: speakcraft-quality
description: Review SpeakCraft implementation before a milestone is considered complete, covering tests, privacy, security, accessibility, cross-platform behaviour, offline states, architecture and product acceptance criteria.
---

# SpeakCraft Quality Gate

Use before declaring a feature or milestone complete.

Check:

## Product

Does the implementation satisfy the actual learner outcome?

Has unnecessary scope been introduced?

## Flutter

Run formatting and static analysis.

Run relevant tests.

Check Android implications.

Check iOS implications.

## Backend

Run formatter/linter/type checks configured by the repository.

Run relevant tests.

Validate request and response schemas.

## Security

Check for:

- committed secrets;
- privileged credentials in mobile;
- unsafe logging;
- missing authorization;
- overly broad database access;
- unsanitised file handling.

## Privacy

Identify whether the feature processes:

- voice;
- transcripts;
- identity information;
- learning history.

Store only what is necessary.

## AI

Ensure structured data is used where reliable machine consumption is required.

Do not trust model-generated scores without validation.

Do not expose hidden/provider implementation details to the learner.

## Accessibility

Check learner-facing language.

Check touch targets.

Check audio alternatives and visible states.

## Offline

Test interrupted connectivity where relevant.

Learner progress must not disappear.

## Completion

Report:

PASS
or
BLOCKED

If BLOCKED, list concrete blockers.

Do not call something complete merely because the happy path works.
