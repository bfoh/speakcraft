# SpeakCraft Engineering Instructions

## Mission

We are building SpeakCraft: "Real English for Real Skills."

SpeakCraft is a voice-first AI vocational English learning application for
iOS and Android.

The initial target users are TVET Beauty & Cosmetology learners in Ghana who
may struggle with practical spoken English.

The product must help learners become better at real communication, not merely
complete language exercises.

Read `docs/PRODUCT_BLUEPRINT.docx` before making significant product,
architecture, curriculum, UX, AI, or data-model decisions.

If implementation details conflict with the blueprint, explicitly document the
conflict before changing the product direction.

---

## Current Product Stage

We are building SpeakCraft Alpha 0.1.

Do NOT build the complete future platform.

Alpha exists to validate one hypothesis:

Can SpeakCraft measurably improve a learner's practical spoken English through
short, vocationally contextualised, voice-first practice?

Initial scope:

- iOS
- Android
- Flutter mobile client
- Beauty & Cosmetology pathway
- five-day Alpha curriculum
- Kora AI tutor
- voice recording
- speech recognition
- simple speaking feedback
- AI Salon
- Help Me Say It
- basic learner progress
- offline-friendly lesson architecture

Do not implement unrelated future features unless explicitly requested.

---

# Engineering Principles

## 1. Build vertical slices

Prefer complete user journeys over large amounts of disconnected infrastructure.

For example:

hear phrase
→ record learner
→ transcribe
→ evaluate
→ give feedback
→ retry

is more valuable than building ten unfinished subsystems.

## 2. Keep the architecture simple

This is an Alpha.

Avoid unnecessary:

- microservices
- event buses
- distributed systems
- complex abstractions
- premature optimisation
- speculative extensibility

Prefer boring, understandable architecture.

## 3. Cross-platform is mandatory

Every mobile feature must work on:

- Android
- iOS

Do not introduce platform-specific behaviour without documenting why.

## 4. Mobile architecture

Use Flutter/Dart.

Prefer feature-oriented organisation.

Expected top-level structure:

mobile/lib/
  app/
  core/
  features/
  shared/

Feature modules should own their presentation, state and domain logic where
practical.

## 5. Backend architecture

Use FastAPI/Python unless an approved architectural decision changes this.

The mobile client communicates with SpeakCraft backend APIs.

Never couple the Flutter client directly to a specific AI provider.

Provider-specific code belongs behind backend interfaces.

## 6. Secrets

Never place:

- OpenAI API keys
- database service-role keys
- privileged tokens
- production secrets

inside the Flutter application or committed repository files.

Use environment variables and documented `.env.example` files.

Never commit real credentials.

## 7. AI provider abstraction

Mobile code should use SpeakCraft concepts such as:

POST /v1/speech/evaluate
POST /v1/kora/respond
POST /v1/help-me-say-it
POST /v1/salon/{session}/turn

Do not expose provider-specific endpoints to mobile.

## 8. Accessibility

The target learner may have limited English literacy.

Prefer:

- large touch targets
- simple language
- strong visual hierarchy
- audio instructions
- icons accompanied by labels
- minimal text
- predictable navigation

Never assume strong reading ability.

## 9. Voice-first UX

Where appropriate:

Listen → Speak → Respond

should be preferred over:

Read → Type → Submit.

Typing is secondary.

## 10. Ghanaian English

Do not treat Ghanaian English or a Ghanaian accent as incorrect merely because
it differs from British or American English.

Pronunciation feedback should optimise for intelligibility.

Accent difference alone is not an error.

## 11. Kora

Kora is an AI vocational English tutor.

Kora must:

- use simple English;
- keep learner-facing responses concise;
- prioritise successful communication;
- correct one important issue at a time;
- give hints before complete answers;
- encourage retrying;
- adapt difficulty;
- remain within the current lesson objective.

Kora must not:

- shame learners;
- overwhelm them with corrections;
- fabricate progress;
- produce long grammar lectures by default;
- force American/British pronunciation;
- behave like an unrestricted generic chatbot.

Read `docs/KORA_PEDAGOGY.md` before modifying Kora behaviour.

## 12. Curriculum

The curriculum is human-designed.

AI adapts practice but does not independently redefine learning objectives.

Curriculum content must therefore be represented as structured data where
possible.

## 13. Offline behaviour

Network interruption must not destroy lesson progress.

Design local state so eligible lesson activities can continue offline.

Synchronise safely when connectivity returns.

## 14. Privacy

Voice data is sensitive.

Collect only what the product needs.

Do not retain raw audio indefinitely by default.

Any persistent English Mirror recording must have a clear product purpose and
appropriate learner consent.

## 15. Testing

Every meaningful feature must include appropriate automated tests.

At minimum run relevant:

- formatter
- linter/static analysis
- unit tests
- integration tests where appropriate

before declaring work complete.

Do not ignore failing tests.

## 16. No fake functionality

Do not silently substitute fake production behaviour.

Mocks are acceptable for development and tests, but clearly label them.

Do not present mocked AI, speech recognition or persistence as completed
production integration.

## 17. Dependencies

Before adding a dependency:

1. determine whether it is actually necessary;
2. prefer established maintained packages;
3. avoid overlapping libraries;
4. document important architectural dependencies.

## 18. Database changes

Use migrations.

Never make undocumented manual production schema changes.

## 19. Error handling

User-facing errors must be understandable.

Bad:

"HTTP 503 upstream exception"

Better:

"We couldn't connect right now. Your progress is saved. Try again when you're
online."

Log technical details separately.

## 20. Observability

Important flows should eventually be observable:

- lesson started
- lesson completed
- speaking attempt
- transcription failure
- feedback generation failure
- AI Salon started/completed
- hint requested
- Help Me Say It used

Do not log sensitive voice content unnecessarily.

---

# Development Workflow

For any substantial feature:

1. Read relevant project documentation.
2. Inspect the existing implementation.
3. Identify assumptions and constraints.
4. Create/update an ExecPlan when the change is substantial.
5. Implement the smallest coherent vertical slice.
6. Run tests and static analysis.
7. Fix failures before proceeding.
8. Update relevant documentation.
9. Summarise:
   - what changed;
   - what was tested;
   - known limitations;
   - next recommended step.

Do not declare a feature complete merely because code was generated.

A feature is complete when it runs, passes relevant checks, and satisfies its
acceptance criteria.

---

# Source of Truth

Priority for product decisions:

1. Explicit current user instruction
2. Product & Technical Blueprint
3. Approved architecture/decision records
4. Current implementation
5. Reasonable engineering judgement

When uncertain about a major product decision, do not silently invent a new
direction.

Document the assumption or ask.

---

# OpenAI Development

When implementing OpenAI APIs or OpenAI-specific functionality, use current
official OpenAI developer documentation rather than relying on remembered API
syntax or deprecated patterns.

When working with OpenAI APIs, Codex, Realtime, speech, models, structured
outputs or other OpenAI functionality, consult the OpenAI developer
documentation MCP before implementing the integration.

---

# Definition of Done

A task is not done until:

- implementation exists;
- relevant tests pass;
- static analysis/linting passes;
- important failure states are handled;
- no secrets are committed;
- Android impact has been considered;
- iOS impact has been considered;
- documentation is updated where necessary;
- acceptance criteria have been checked.
