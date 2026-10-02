# SpeakCraft Alpha: remaining work, with device testing last

Updated 2026-10-02. This is an execution order for the five-day Beauty & Cosmetology Alpha. It does not expand the product into the full 30-day platform.

## Build and verify without physical devices

1. **Learner confidence check-ins — implemented and locally validated.** Ask the same optional 1–5 self-report question after Starting assessment and after Day 5 practice. Store locally and label it as the learner's feeling, not a speaking score. See [Sprint 17](../.agent/plans/sprint-17-confidence-check-ins.md).
2. **Consultation evidence.** The current AI Salon stores completed reply count and recorded-answer time. Measure a whole consultation separately if the Alpha will test the Blueprint's 90-second goal. Distinguish elapsed exchange time from learner speech and from successful task completion. Do not infer success from length alone.
3. **Comparable Day-5 challenge design.** Specify a fixed or bounded Day-5 task measuring the same customer acts as the Day-1 baseline: understand the need, ask a question, recommend and explain. Keep any first implementation unscored until local review. The current Day-5 AI Salon is useful practice but differs from the fixed Day-1 prompts.
4. **Assessment research workflow.** Use the [draft rubric](ASSESSMENT_RUBRIC_DRAFT.md) to prepare a consented reviewer pack, a simple rating form and de-identified sample handling. The current recordings expire at next launch; any export or retention needs an explicit choice, access rules and deletion design before implementation.
5. **Pilot readiness and security.** Review provider retention, error logs, authentication/rate limits, account and deletion needs, and the deployment boundary before inviting real learners. The present shared pilot code is for an internal pilot, not public access.
6. **Automated validation.** For each slice, run Flutter formatting, analysis and tests; backend checks where changed; Android and iOS builds; curriculum sync; and GitHub CI. Simulators and test fakes help verify code paths but do not establish real audio behavior.

## External evidence required before assessment or a learner pilot

- Ghanaian vocational and language-education review of the current prompts, provisional image, draft rubric, example phrases and support-language/voice behavior.
- A consented target-learner feasibility study, independent rating of shared samples and a comparison protocol. A first 5–10 learner Alpha can expose usability problems but cannot by itself establish a precise speaking scale.
- A configured provider account and server-only key to exercise real transcription, Kora and AI Salon quality with consented Ghanaian-accented speech. The repository contains no key.
- A plain-language consent and retention policy before keeping or exporting English Mirror recordings. No current score or Day-1/Day-5 improvement claim is authorized by the available evidence.

## Final task: connected-device acceptance

After the code, documentation and remote checks above, connect Android and iOS devices. Run the native journey on both: onboarding, offline lessons, microphone permission/denial, recording/playback, speaker and wired/Bluetooth routes, interruptions, large text, screen reader, connection loss/retry, Privacy reset and provider requests. Record failures and fixes before a learner pilot. The user requested this physical-device phase last.
