# Day-3 consultation duration: measurement proposal

**Status: definition for review; no 90-second consultation result in the app.** The Blueprint calls for a 90-second customer consultation on Day 3. The present AI Salon saves the highest completed reply count and the sum of accepted microphone recording time. Those numbers measure participation, not the duration or success of a full consultation.

## Proposed unit and event boundary

A consultation attempt begins when the learner actually hears or reads the first customer line and ends after a final customer/learner close or an explicit stop. Record customer line delivery, learner recording start/stop, transcription and provider request start/stop, interruptions, replays, and whether the exchange ended normally or early. Store the attempt's scenario/content version. Do not add durations from separate attempts to reach a target.

Report at least two separate quantities: **learner recording seconds** (already available, can include silence) and **foreground exchange elapsed seconds** (customer and learner turns, excluding server waits and time in the background). A facilitator may also note audible learner speech time from consented audio; microphone-open time is not that measure. Show the actual attempt and missing-data state rather than silently replacing it with zero. A 90-second threshold alone cannot establish that the learner understood a need, asked a useful question, recommended appropriately or closed politely.

## Decisions before implementation

An educator and product owner must settle whether listening to a replay, reading a customer line, planning silently and waiting for speech recognition count toward the consultation duration. They must also decide whether the current turn-by-turn asynchronous AI Salon resembles the workplace task enough to test the 90-second goal. Network delays should not raise a learner's duration. Background time, interruptions and failed provider replies must be excluded or marked incomplete. Decide how to handle learners who speak clearly and finish in less than 90 seconds; they should not be treated as unsuccessful solely for brevity.

After those decisions, instrument the conversation controller with a monotonic event clock, unit-test pause/resume and retry boundaries, and run Android/iOS real-audio checks in the final device phase. Keep task completion as a separately reviewed outcome. Until then, the app's wording must stay **“time recording answers”** and must not say “90-second consultation completed.”
