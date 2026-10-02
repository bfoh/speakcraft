# SpeakCraft starting assessment: research-derived rubric (draft v0.1)

**Status: design and reviewer preparation only.** This is a SpeakCraft-authored rubric, not an official CEFR, ACTFL, IELTS or Ghana CTVET assessment. No Ghanaian educator has reviewed it, no local learner responses have been rated with it, and it must not generate a learner-facing score yet. It applies to the seven current Day-1 recordings in `curriculum/alpha.json` (the Blueprint's five assessment parts). It does not change the app's current unscored, temporary recording flow.

## What the research supports

- The [ACTFL 2024 proficiency guidance](https://www.actfl.org/news/revised-actfl-proficiency-guidelines-released) frames speaking in terms of accomplishing communication objectives. SpeakCraft therefore starts with whether a listener can understand and act on the learner's message, rather than counting grammar errors. This is an adaptation for a narrow vocational task, not an ACTFL rating.
- The [Council of Europe's updated phonology guidance](https://www.coe.int/en/web/common-european-framework-reference-languages/phonological-competence) explicitly favors intelligibility over imitation of a native-speaker accent. Ghanaian English features alone are not errors. A pronunciation note needs a specific moment where a listener misunderstood the intended meaning.
- The [CEFR Companion volume](https://rm.coe.int/cefr-companion-volume-with-new-descriptors-2020/16809ea0d4) describes practical interaction, information exchange and clarification. For salon work, asking a useful question and repairing a misunderstanding are observable communication successes. These descriptors inform the design but do not establish a CEFR level for a SpeakCraft learner.
- [Cambridge English's validation approach](https://www.cambridgeenglish.org/english-research-group/validity-and-validation/testcycle.aspx) separates task specification, rater standardisation and empirical validation. The draft below addresses specification only. Reviewer agreement and local performance evidence are still required.
- [UNESCO/UNICEF guidance on multilingual assessment](https://www.unesco.org/en/articles/guidance-classroom-based-assessment-multilingual-learners-assessing-languages-literacies-and) argues for assessment that documents multilingual learners' capabilities and considers language choices. Raters should note when a learner uses a support language to convey meaning; they should not silently treat that as a failure of vocational understanding. Whether English-only performance is required for a particular outcome must be stated in that task's purpose.
- Ghana's [CTVET approved-programme list](https://ctvet.gov.gh/cbt-approved-programmes/) confirms Cosmetology, Beauty Therapy and Hair Technology as recognised training areas. It does **not** validate these prompts or this rubric. Local vocational educators must judge whether each salon situation and its expected response are realistic.
- The [AfriSpeech-200 research dataset](https://arxiv.org/abs/2310.00274) includes African-accented English, including Ghanaian speech. It is evidence that accent coverage must be checked in speech technology; it is not a validation set for SpeakCraft's learners or a reason to use transcript accuracy as a pronunciation score.

The familiar IELTS four-category speaking rubric provides useful context, but [IELTS assesses a different, general-English purpose](https://takeielts.britishcouncil.org/results/how-is-ielts-assessed). Copying its band scores or giving the same weight to grammar and vocational task success would not answer SpeakCraft's Alpha question.

## Intended interpretation

This is a **low-stakes diagnostic of practical communication in these prompts**, not a general English level, job qualification, clinical measure, personality judgment or certificate. The unit of observation is a task attempt. The desired evidence is: Did the learner convey the requested meaning, understand the customer, ask for needed information and keep the exchange moving? Grammar and word choice matter when they change meaning or make the task hard to complete. A brief but successful answer can be stronger than a long polished answer that misses the customer's need.

### Evidence states and task-outcome anchors

Each task gets one outcome only after a rater can hear a valid attempt. These **0–2 anchors are provisional internal labels**, not published scores or cutoffs:

| Code | Meaning | General anchor |
| --- | --- | --- |
| `2` | Outcome achieved | The task's essential meaning is clear and actionable without a rater supplying missing information. Minor language errors are acceptable. |
| `1` | Partly achieved | Some task-relevant meaning is clear, but an essential element is missing or a listener would need a follow-up to act confidently. |
| `0` | Outcome not yet shown | An audible response is present, but its meaning does not address the task or cannot be recovered after one neutral replay. |
| `NE` | Not enough evidence | Missing file, recording fault, inaudible audio, interrupted prompt, skipped task or another administration problem. Record the reason; do not convert `NE` to zero. |

Before rating, record the **stimulus actually used** (picture or audio-described alternative), whether the full prompt played, and whether help or a replay was given. If a rater cannot distinguish a quiet learner response from microphone failure, use `NE`. If the learner explicitly declines to share personal information, do not penalise that choice; rate the remaining professional introduction evidence. If a recording contains a clear no-response despite a working microphone and understood prompt, a rater may use `0` with a note. These rules need local reviewer confirmation.

### Seven current tasks and task-specific anchors

These paraphrase the authored prompts. They are intentionally about **communicated outcomes**, not required exact words.

| Current item | What `2` would show | What `1` would show | Main evidence limit |
| --- | --- | --- | --- |
| `baseline-introduction` | Understandable introduction of what the learner studies and a reason or goal. | One of study or reason is understandable. | Name and home town are personal; refusing them must not reduce the result. One monologue does not show conversation skill. |
| `baseline-picture` | Describes at least two relevant actions, people or objects in the shown salon scene **or** the offered braiding alternative so a listener understands what is happening. | One relevant element is conveyed without a clear relationship or action. | Picture and fallback differ in difficulty; record which was used. The current picture is provisional and cannot support a precise reference-answer check. |
| `baseline-procedure` | Explains a familiar salon procedure in a sequence a listener can follow, with at least two meaningful steps. | Conveys the procedure or a step, but order or an essential step is unclear. | This rates explanation, not technical competence or safety certification; the learner may choose any familiar procedure. |
| `baseline-listening` | Correctly conveys the customer's wish for easy-to-maintain braids and uncertainty about long versus short, then asks a relevant next question. | Correctly conveys at least one of those needs, or asks a useful next question without showing both key facts. | One scripted customer utterance cannot justify a broad “Listening” ability label. Separate notes should identify which facts were heard and which question was asked. |
| `baseline-customer-1` | Responds to the request for help and moves toward understanding the desired braids, for example by offering help or asking what style is wanted. | Acknowledges the customer but does not move the consultation forward. | A fixed prompt does not show spontaneous listening or live turn-taking. |
| `baseline-customer-2` | Asks a question that would help choose an easy-care style, such as length, maintenance or preference. | Asks a related but insufficient or unclear question. | Do not require one model sentence; a useful question can be phrased many ways. |
| `baseline-customer-3` | Makes a plausible recommendation and gives a reason connected to the customer's wish for something simple. | Gives a recommendation without a useful reason, or a reason without a clear recommendation. | Do not require a specific hairstyle, invent a price or infer whether the customer would accept the advice. |

For `0`, use the general anchor. A rater must note the phrase or moment that led to `0` or `1`; a transcript alone is insufficient to judge intelligibility. The rater should not judge professional correctness beyond obvious task contradictions without a vocational expert.

## Separate observations; avoid a premature total score

The seven outcomes should **not** be averaged into a single ability number. The tasks differ, the listening sample is small, the picture has two stimulus modes, and the role-play is fixed rather than interactive. Record these observations alongside the task outcome when the task affords them:

| Observation | What to record | What it cannot prove yet |
| --- | --- | --- |
| Meaning clear | Brief evidence of the message a listener understood; note any necessary clarification. | General speaking level from one clip. |
| Listening facts | On `baseline-listening`, whether easy maintenance and unresolved length were understood. | Broad listening comprehension. |
| Intelligibility | Specific words or meaning a Ghanaian-English-familiar listener could or could not recover from audio, with replay and audio-quality notes. | Accent “correctness” or a speech-model pronunciation score. |
| Workplace language | Useful salon terms and whether they convey the intended meaning in picture, procedure and customer tasks. | A vocabulary-size estimate from short prompts. |
| Interaction | Whether the three customer replies acknowledge needs, ask a question and give a reasoned recommendation. | A real 90-second consultation or natural turn-taking. |
| Assistance | Prompt replay or help actually given, using the existing 0–3 assistance ladder only when it was recorded. | Independence from an unlogged or changed prompt. |
| Confidence | A separately asked learner self-rating, with wording and scale recorded. | Confidence inferred from speed, hesitations, volume or accent. |

The Blueprint's proposed learner-facing labels—Speaking, Listening, Pronunciation, Work Vocabulary, Conversation and Confidence—are **reporting ideas**, not six validated scores. In particular, rename any future “Pronunciation” result to an intelligibility-focused explanation unless local review supports a fairer interpretation. Do not populate missing dimensions with model estimates.

## Rater procedure for a small, consented study

1. Confirm prompt, stimulus mode, recording condition and consent. Use `NE` if the attempt cannot be heard or the prompt was not delivered as intended.
2. Listen once for overall meaning and task completion, then at most one neutral replay to resolve ambiguity. Do not read an ASR transcript before the first judgment; machine errors may bias the rater.
3. Assign task outcome `0`, `1` or `2`, citing the observable evidence. Record listening facts and other applicable observations separately.
4. Note a possible intelligibility issue only when it changed or blocked understanding. Record what was misunderstood and whether replay clarified it. Do not mark Ghanaian English pronunciation merely for sounding unlike US or UK English.
5. Record prompt help/replays and the chosen picture alternative. Do not infer unrecorded assistance.
6. Give one short, actionable learner feedback point after rating, in Kora's teaching style. Keep the detailed rating notes internal.

Suggested de-identified rating row for a future research tool: `rubric_version`, `random_attempt_id`, `task_id`, `stimulus_mode`, `prompt_delivery_ok`, `audio_quality`, `evidence_state`, `outcome_0_2`, `outcome_evidence`, `listening_facts`, `intelligibility_event`, `assistance_observed`, `rater_id`, `rated_at`. Store the consent record separately from the audio and rating row. This is a design field list, **not an implemented database table**.

## Validation protocol before any learner-facing result

The stages below are release gates, not a claim that a small pilot establishes a psychometrically validated test.

1. **Content review.** Have at least one Ghanaian Beauty/Cosmetology or Hair Technology educator and one English-language teaching or assessment specialist review each stimulus, expected outcome, fallback and learner wording. Record disagreements and revisions. Check that the task reflects real local customer communication. Review the generated picture with learners who use screen readers or have low vision. The named reviewers must approve a numbered rubric version and task set.
2. **Administration check.** On physical Android and iOS devices, verify the whole prompt is heard, recording/playback works with common audio routes, prompts can be replayed consistently and all intended answers survive through review. Make a low-literacy usability pass with target learners. Record task duration, replays, skips and the reason for `NE` without treating them as ability.
3. **Consent and sample.** Write plain-language consent for audio review, who hears it, where it is stored, retention/deletion dates, withdrawal and whether any provider processes it. Obtain permission before collecting recordings. The current app deliberately deletes starting answers at next launch and has no reviewer export; a separate consented collection workflow must be designed before independent raters can hear the same samples. Recruit a small, diverse feasibility sample of target learners with varied speaking backgrounds and devices. The Blueprint's first 5–10 learners can reveal usability and obvious task defects; they cannot by themselves establish a population-level score scale.
4. **Rater calibration.** Two trained raters independently assess a shared set of consented responses, initially blind to learner identity, ASR output and each other's labels. Discuss disagreements against the task anchors, add anonymised anchor examples only with permission, revise the rubric and repeat. Report exact and adjacent agreement by task, unresolved disagreements and `NE` frequency. Set prospective release thresholds with the assessment specialist before a larger evaluation rather than choosing a favorable threshold after seeing results. [Cambridge English describes standardisation and empirical validation as distinct stages](https://www.cambridgeenglish.org/english-research-group/validity-and-validation/testcycle.aspx).
5. **Fairness and technology check.** Compare ratings and missing-evidence rates across prompt/stimulus modes and device/audio conditions. With consent, compare ASR transcripts with human transcripts of Ghanaian-accented responses before using text-based automation. Review whether a rater's familiarity with Ghanaian English changes judgments. Audit selected low and high ratings with a second rater. Use no automatic pronunciation or task score until it agrees sufficiently with human judgments under a predeclared criterion.
6. **Comparable follow-up.** Author a Day-5 challenge measuring the **same underlying acts**: understand a customer's need, ask a relevant question, recommend and explain. Use equivalent but non-identical prompts, similar assistance and recording conditions, and task-level comparisons. The current Day-5 AI Salon rehearsal count and recorded-answer time are participation measures, not a comparable outcome. Define the comparison and its uncertainty before any “improved” message.
7. **Result design.** After the evidence above, pilot simple learner-facing statements such as “You asked what style the customer wanted” or “Next time, give one reason for your recommendation.” Provide audio for the result, avoid a false precision chart, and allow correction or contest of a misheard response. Decide separately whether retaining an English Mirror recording provides enough learner value to justify explicit opt-in and a deletion policy.

### Release rule

Until content approval, consent/retention design, physical-device administration, independent-rater agreement and a comparable follow-up protocol exist, SpeakCraft may show **recording completion and self-review only**. It must not show a proficiency band, six-dimension profile, Day-1/Day-5 improvement claim or automated assessment result. Research has removed the need to invent the first draft; it has not replaced local educator judgment or empirical validation.

## How to obtain the remaining review

The project owner does not need to invent an assessment rubric or locate an official SpeakCraft-specific one. This document is the reviewable starting point. The [Ghana CTVET accredited-institutions directory](https://ctvet.gov.gh/accredited-institutions/) can help identify a Beauty Therapy, Cosmetology or Hair Technology instructor; it is a directory, not an endorsement of any particular reviewer. A Ghana-based English-language teacher or language-assessment specialist can review the clarity and rating anchors. A single person may cover both roles if qualified, but independent perspectives are preferable. No one should receive learner audio until the consent and handling plan is approved.

Send prospective reviewers the Blueprint's sections 9, 13, 14 and 28, the seven authored prompts and provisional picture, and this draft. Ask for a **written** response on: (1) realism and clarity of each task; (2) whether each `2`/`1` anchor describes useful, fair communication; (3) Ghanaian English and support-language treatment; (4) picture/fallback accessibility; (5) what a truly comparable Day-5 challenge would require. Record their name/role, review date, exact document version, suggested changes and approval or remaining objections in a future decision record. This is content review; it does not substitute for independent rating of consented responses.

Suggested short request, for the project owner to send when ready:

> We are developing SpeakCraft, a short speaking-practice app for Ghanaian Beauty and Cosmetology learners. Could you review seven salon communication prompts and a draft outcome rubric for local realism, clarity, accessibility and fair treatment of Ghanaian English? We need written comments on the attached version; no learner recordings are included. Please let us know your relevant teaching or assessment experience and availability.

## Open decisions for the review team

- Should the introduction avoid asking for home town or legal name altogether? The current prompt does ask, but these details are unnecessary to judge practical communication.
- Should the picture and audio-described alternative become one common nonvisual stimulus for comparability?
- Should the listening item replay once by default, and how is that assistance logged?
- How will the customer replies become genuinely interactive without making Day-1 and Day-5 incomparable?
- Which learner-facing dimensions, if any, have enough evidence to report after the pilot?
- What sample size and prospective agreement/fairness thresholds should an assessment specialist set for release?

## Source and version note

Research checked 2026-10-02. Links above are primary institutions or original research. The numeric anchors and task criteria are SpeakCraft design proposals; the cited organisations have not endorsed them. Revise this document and record a new version when local reviewers or pilot evidence change the construct, tasks or reporting rules.
