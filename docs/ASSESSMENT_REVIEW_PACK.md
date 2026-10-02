# SpeakCraft Alpha content-review pack

**Review status: awaiting Ghanaian vocational and language-education review.** This pack contains no learner recordings. Use the exact wording in [`curriculum/alpha.json`](../curriculum/alpha.json), content version **0.1.2**, and the provisional anchors in [the draft rubric](ASSESSMENT_RUBRIC_DRAFT.md). Record the version and date on every returned review. The generated salon image at `mobile/assets/assessment/salon-scene-provisional.png` is provisional and needs its own accessibility review.

## What reviewers should decide

Ask a Beauty/Cosmetology or Hair Technology educator and an English-language teaching or assessment specialist to review independently, then record disagreements. For each task, decide whether the salon situation is realistic in the intended Ghanaian training context, the customer line and instruction are understandable to a learner with limited English literacy, the spoken and written versions match, and the response can show the stated communication act. Comment on Ghanaian English, support-language use, the picture alternative, replay/help rules and any culturally narrow assumption. Mark **approve / revise / remove**, with proposed wording. An approval applies only to the named content/rubric versions.

| Task IDs in curriculum | Intended evidence | Comparison question for reviewers |
| --- | --- | --- |
| `baseline-introduction`, `baseline-picture`, `baseline-procedure` | Introduce study/reason, describe a scene, explain a procedure | No matching Day-5 task exists. Do not include these in a Day-1/Day-5 comparison. Is any personal information unnecessary? Is the visual alternative fair? |
| `baseline-listening` ↔ `day5-need` | Hear the customer's need and ask a useful next question | Are easy-care/length and work-comfort/length comparable demands without repeating the same wording? |
| `baseline-customer-1` ↔ `day5-greeting` | Acknowledge and open a braid consultation | Does either customer line offer more help or imply a preferred answer? |
| `baseline-customer-2` ↔ `day5-question` | Ask a question that helps choose a style | Are the needs similarly clear? Would several different questions be acceptable? |
| `baseline-customer-3` ↔ `day5-recommend` | Recommend a plausible style and explain why | Do the reasons require similar vocational knowledge? Is the no-price instruction clear? |
| `day5-close` | Close and describe a safe next step | This extends the Blueprint's Day-5 goal. It has no Day-1 match and must not enter a paired comparison. |

These are **proposed mappings**, not established equivalent forms. Both flows play authored prompts through device speech, permit replay and capture one answer per item, but the first includes a picture/procedure and the last includes a closing. The app currently logs neither actual prompt replay nor assistance; a research administration protocol must record those separately. No total score or improvement statement follows from the mapping.

## Review response sheet

Return one row per item or group, plus a general decision:

| Field | Reviewer entry |
| --- | --- |
| Reviewer name, role, institution and relevant experience | |
| Date; curriculum version; rubric version; image version if reviewed | |
| Item ID and decision: approve / revise / remove | |
| Customer realism and vocational accuracy | |
| Learner wording and audio clarity | |
| Acceptable communicated outcomes and possible misunderstandings | |
| Ghanaian English, support language and accessibility concerns | |
| Proposed replacement wording or anchor | |
| Remaining objection or condition for approval | |

For the whole task set, ask whether the Day-5 lines are similar enough to compare **each paired act**, what administration rules are needed (prompt replay, hints, picture alternative), and whether a simple learner-facing explanation would be understood. Keep the two reviewers' first written responses separate before discussing changes. Record each accepted editorial change in `docs/DECISIONS.md` and increment the curriculum/rubric version.

## Boundary before any learner samples

Content review can use this repository without audio. A separate sample study needs a [consent and handling decision](PILOT_READINESS.md) first: exact learner-facing purpose, who listens, where encrypted files live, transfer method, retention/deletion and withdrawal, provider processing, and whether samples can be used as anonymised anchors. The present app removes recordings on next launch and has no export. Do not ask a learner to send files informally or use the internal pilot token as a sample-access system.
