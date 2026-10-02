# SpeakCraft Alpha pilot readiness gates

Status: **internal development build**. The app can run its five-day guided journey and unscored local tasks, but it is not ready for public access or a scored learner study. Complete the evidence below before inviting real learners. Physical Android/iOS acceptance is the **last** execution phase, as requested by the project owner.

| Gate | Evidence required | Current status |
| --- | --- | --- |
| Content | Written review of curriculum 0.1.2, picture/fallback, support-language behavior and rubric v0.1 by Ghanaian vocational and language-education specialists; decisions/version recorded | Open; [review pack](ASSESSMENT_REVIEW_PACK.md) ready |
| Assessment | Consented sample protocol, two independent raters, calibration, `NE` rules, predeclared agreement/fairness thresholds, approved Day-1/Day-5 task mapping | Open; [worksheet](ASSESSMENT_RATING_WORKSHEET.md) ready; no result in app |
| Consultation measure | Agreed [event and timing definition](CONSULTATION_MEASUREMENT.md), confirmation that the AI Salon task represents a customer consultation, real-audio administration check | Open; only reply count and recording time exist |
| Learner consent and data handling | Plain-language choice for audio review/retention, purpose, recipients, storage region/method, encryption/access, exact deletion date, withdrawal and backup/provider treatment | Open; no audio export or retention feature |
| Provider | Owner-configured server-only key, checked account retention/data-use terms, tests of transcription and feedback on consented target speech, error/cost limits | Open; repository has no key and CI uses fakes |
| Backend exposure | Hosting boundary, TLS, per-learner authentication/authorization, abuse and rate limits, monitoring without learner content, incident and deletion process | Open; shared pilot code is internal only |
| Software quality | Flutter/backend checks, curriculum sync, Android/iOS simulator builds, CI, dependency compatibility review | Automated checks active; `flutter_tts` future Kotlin/Swift Package Manager warnings need tracking |
| Learner feasibility | Small consented session with target learners, audio-first comprehension, prompt replay, failed connection, low-literacy wording and image alternative | Open; after content/consent decisions |
| Physical-device acceptance | Android and iOS journey, permissions, recording/playback, wired/Bluetooth routes, interruptions, screen reader, large text, offline/retry and Privacy reset | Deferred as final task |

## Operating boundary now

The current FastAPI bearer code protects internal test routes only. Do not put it or a provider key in the mobile build. The server has no per-learner identity or cloud progress store. Do not publish it as a public learner service. Health only proves process liveness, not configured speech or pedagogical quality. The app's local Clear phone data cannot revoke a provider request already sent or erase device backups.

## Decisions required before collecting or retaining samples

The project owner and reviewers must choose the study purpose, exact consent language, audio recipients, approved transfer/storage, retention and deletion period, withdrawal mechanism, participant compensation if any, and who handles technical failures. Document provider terms and whether speech/feedback requests are enabled during the study. Only then design an opt-in export/retention implementation and test it. Do not create a database of recordings to solve this ahead of those decisions.

## Final connected-device pass

When the earlier gates are ready, connect one representative Android and one iOS device. Run the [connected-device acceptance checklist](DEVICE_ACCEPTANCE_CHECKLIST.md), record device/OS/audio route and failure evidence, fix critical issues, and repeat failed cases. A simulator build is valuable code validation but is not evidence that real microphone, permissions, installed voices or audio routes work.
