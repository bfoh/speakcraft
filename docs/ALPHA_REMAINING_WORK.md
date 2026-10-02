# SpeakCraft Alpha: remaining work, with device testing last

Updated 2026-10-02. This is an execution order for the five-day Beauty & Cosmetology Alpha. It does not expand the product into the full 30-day platform.

## Build and verify without physical devices

1. **Learner confidence check-ins — implemented and locally validated.** Ask the same optional 1–5 self-report question after Starting assessment and after Day 5 practice. Store locally and label it as the learner's feeling, not a speaking score. See [Sprint 17](../.agent/plans/sprint-17-confidence-check-ins.md).
2. **Consultation evidence — definition prepared; implementation awaits task decision.** The current AI Salon stores completed reply count and recorded-answer time. The [measurement proposal](CONSULTATION_MEASUREMENT.md) defines event boundaries and unresolved timing rules for a full exchange. An educator/product decision is needed before adding a 90-second measure; duration cannot stand in for successful task completion.
3. **Comparable Day-5 challenge design — first unscored implementation complete.** Five fixed customer prompts now capture need, greeting, question, recommendation with reason and close in separate temporary audio. Educators must review realism and equivalence before any Day-1/Day-5 result. The current Day-5 AI Salon remains variable practice.
4. **Assessment research workflow — templates ready, external evidence open.** The [content-review pack](ASSESSMENT_REVIEW_PACK.md), [rating worksheet](ASSESSMENT_RATING_WORKSHEET.md) and [draft rubric](ASSESSMENT_RUBRIC_DRAFT.md) define the review. Recordings still expire at next launch; consent, access, transfer, retention and withdrawal decisions precede any sample collection or export.
5. **Pilot readiness and security — gate documented, evidence open.** Follow the [readiness gates](PILOT_READINESS.md) for provider terms, authentication/rate limits, deletion, content review and hosting. The present shared pilot code is for internal testing only.
6. **Automated validation.** For each slice, run Flutter formatting, analysis and tests; backend checks where changed; Android and iOS builds; curriculum sync; and GitHub CI. Simulators and test fakes help verify code paths but do not establish real audio behavior.

## External evidence required before assessment or a learner pilot

- Ghanaian vocational and language-education review of the current prompts, provisional image, draft rubric, example phrases and support-language/voice behavior.
- A consented target-learner feasibility study, independent rating of shared samples and a comparison protocol. A first 5–10 learner Alpha can expose usability problems but cannot by itself establish a precise speaking scale.
- A configured provider account and server-only key to exercise real transcription, Kora and AI Salon quality with consented Ghanaian-accented speech. The repository contains no key.
- A plain-language consent and retention policy before keeping or exporting English Mirror recordings. No current score or Day-1/Day-5 improvement claim is authorized by the available evidence.

## Final task: connected-device acceptance

After the code, documentation and remote checks above, connect Android and iOS devices and use the [final acceptance checklist](DEVICE_ACCEPTANCE_CHECKLIST.md). Run the native journey on both: onboarding, offline lessons, microphone permission/denial, recording/playback, speaker and wired/Bluetooth routes, interruptions, large text, screen reader, connection loss/retry, Privacy reset and provider requests. Record failures and fixes before a learner pilot. The user requested this physical-device phase last.
