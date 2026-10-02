# Research-derived starting assessment rubric

## Goal

Produce a usable draft rubric and validation protocol for SpeakCraft's seven Day-1 starting-assessment recordings, so the project can prepare a defensible Day-1/Day-5 comparison without claiming that a literature review is educator validation.

## Context

The Blueprint calls for a five-part Day-1 conversation-like assessment, simple learner-facing feedback, and comparison with a later practical conversation. The app currently captures seven recordings across those five parts, keeps them temporarily, and shows no result. Ghanaian Beauty & Cosmetology learners are the intended first population.

## Non-goals

No automatic scoring, learner-facing result, CEFR/ACTFL/IELTS level, national qualification claim, assessment API, retained baseline, pilot data collection or revised prompt in this work.

## User Journey

The learner's existing recording journey stays unchanged. Later, after review and consent, a learner can optionally receive concise, evidence-based feedback on tasks they actually attempted and compare a genuinely matched follow-up task. Missing audio or an untested dimension must never be reported as low ability.

## Technical Approach

Use primary assessment sources to define observable task outcomes, separate communication from grammar/accent conformity, map each current task to evidence, and document rating instructions plus a small validation study. Keep this as a versioned draft document rather than adding unvalidated production scoring logic.

## Files / Components

Add `docs/ASSESSMENT_RUBRIC_DRAFT.md`; update `README.md` and `docs/DECISIONS.md`. Existing curriculum and assessment code remain unchanged.

## Data Model

No data change. The draft specifies future rating fields but authorizes no storage of ratings, audio, transcripts or identity information.

## API Contract

No endpoint change. A future assessment endpoint must be designed only after validation, privacy and authentication decisions.

## Privacy / Security

Do not collect participant audio for the proposed validation study without explicit, informed consent, a purpose, limited access, a retention period and deletion route. Public research sources contain no learner data. This work adds no app permissions or secret.

## Offline Behaviour

The existing unscored assessment and local replay continue offline. The draft document has no runtime dependency.

## Android / iOS Considerations

No platform code changes. Later validation must test identical prompts, recording quality, playback, permission and interruption behavior on physical Android and iOS devices.

## Milestones

1. Inspect Blueprint, current tasks, instructions and relevant skills.
2. Research primary assessment, fairness and Ghanaian speech evidence.
3. Write a task-linked rubric with explicit non-observable cases and source traceability.
4. Define a feasible review, rater-calibration and pilot protocol with release gates.
5. Check consistency with current curriculum, links and documentation; commit and push.

## Acceptance Criteria

- Every existing baseline task has a stated observable outcome and an evidence limitation.
- Rating anchors distinguish task failure from missing/poor-quality evidence.
- Ghanaian English accent variation is not treated as an error by itself.
- Confidence requires learner self-report rather than inference from voice.
- The document states exactly what review and pilot evidence would be needed before learner-facing results.
- No app behavior, storage, API or permission changes are introduced.

## Validation

```sh
python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path('curriculum/alpha.json').read_text())
print([(item['id'], item['part']) for item in data['baseline_items']])
PY
python3 scripts/sync_curriculum.py --check
git diff --check
```

Manually verify source URLs and each task mapping. Existing tests/builds are unaffected because no executable or packaged curriculum file changes.

## Risks / Unknowns

- A written rubric does not establish validity, reliability, fairness or readiness to auto-score.
- The picture is provisional; the listening item has one scripted prompt; the role-play is three fixed replies rather than a live conversation.
- Day 1 and Day 5 are not yet equivalent tasks, and the app does not record assistance or confidence for this assessment.
- No educator or learner pilot participant is available in this session.
- Current temporary assessment files have no consented export path for independent review; that is a later, separately governed implementation task.

## Decision Log

- 2026-10-02: Prepare a research-derived, task-linked draft and validation protocol. Keep the production assessment unscored until local content review and pilot evidence support interpretation.
- 2026-10-02: Keep rating anchors in a reviewer document rather than executable curriculum or an endpoint. The current seven tasks cannot justify a total or six-dimension learner score, and no consented rating sample exists.

## Progress

- [x] Read current product and repository context.
- [x] Research primary assessment and speech-fairness sources.
- [x] Write rubric and validation protocol, including a reviewer request and consented-study prerequisites.
- [x] Validate all seven task IDs, canonical curriculum sync, source links and Git whitespace; quality gate PASS for the research document, BLOCKED for production scoring.
- [x] Commit and push the documented draft.
