# Alpha security and privacy

## Data handled

The app stores profession, English support choice, onboarding position, current prompt position for each of the five days, authored IDs of daily speaking steps attempted, the highest number of customer replies completed in a Day-3/Day-5 AI Salon rehearsal, the longest total answer-recording seconds in a rehearsal, and self-rated word review timing in private SQLite storage. It does not persist names, accounts, transcripts, learning scores or cloud identifiers. Attempt markers, reply counts and recording time describe participation, not speech quality.

The microphone records only after an explicit learner action and OS permission. Mono audio is written to the app's private temporary cache. One current take is retained for in-app navigation. Starting a replacement, moving to another phrase, pressing Delete recording, or launching the app again removes it. The OS may evict cache files. A recording is not an English Mirror artefact or durable lesson history.

The optional Starting assessment uses a separate private microphone folder and stages up to seven `.m4a` answers in another private temporary folder. The app explains this before capture. Each copy is staged before the next task unlocks; a failed copy keeps the original take for retry. The position is held in memory only. No assessment recording, transcript, score or identifier is sent to a server. All staged files are removed on the next app launch, on the assessment's Clear recordings action, or by Clear phone data. A process crash may leave temporary files until the next launch; OS cache eviction can remove them earlier. This is not a durable baseline or a Day-5 comparison record.

Learners can explicitly replay the current starting-assessment take or a staged answer during that app session. Playback reads the private local file and makes no network request. Leaving the assessment, beginning another recording, app interruption and either clear action stop playback; the player releases its file source before deletion. Replay adds no transcript, score or retention period.

The optional confidence check-ins after Starting assessment and Day 5 record the learner's own 1–5 readiness choice and the time of the latest choice in local SQLite. The two responses are never sent by this feature and are removed by Clear phone data. They do not measure speech quality, and the app does not infer confidence from recorded voice. Clearing only the temporary starting recordings does not clear a saved check-in; Clear phone data does.

**Hear my words** is a separate learner action that uploads the current take to the SpeakCraft backend for transcription. The transcript stays in app memory with that take. The backend reads at most 4 MiB and stores neither audio nor transcript. The configured provider receives audio for transcription; review the provider account's retention and data-use settings before processing real learner recordings. A failed connection leaves the local take available for manual retry, but relaunch still clears it.

**Help me say it better** is another explicit action. It sends the displayed transcript and selected curriculum prompt IDs to the backend; the backend looks up the authored objective and asks the provider for short structured feedback with storage disabled in the request. Feedback stays in app memory and is cleared when the take or prompt changes. The backend stores no feedback. The provider's actual retention settings and teaching quality still require review before real learner use.

**Talk with Kora** uses separate record, transcribe and send actions. A bounded turn history and the current transcript go to the backend only on Send reply. The backend validates the Day-1 goal and sends this transient context to the provider with storage disabled in the request. Dialogue is held only in app memory while the screen is open; leaving clears it. A connection failure keeps the current answer for explicit retry.

Conversation audio uses its own private temporary cache folder. Entering or leaving the conversation does not remove a Day-1 lesson practice take. Leaving the conversation deletes its current take; app relaunch clears any remaining temporary lesson, dialogue and assessment takes.

**AI Salon** reuses that temporary dialogue recorder with the same explicit record, transcribe and send steps. The selected scenario ID, bounded customer/learner history and current transcript reach the backend only when the learner sends a reply. The backend resolves the authored scenario and uses the provider with storage disabled in the request. It stores no session or exchange. Leaving the screen clears the local dialogue and current take, while a failed request keeps them available for retry.

The Day-3 and Day-5 scenarios use the same voice/transcript privacy boundary. At a terminal exchange, only the best completed learner-reply count and longest total recorded-answer time are saved locally. This duration may include silence and excludes the customer's turns. No conversation words, audio, full consultation duration, success judgement or challenge score is persisted.

**Help Me Say It** also uses that recorder. The learner reviews a tentative intention transcript before explicitly requesting an expression. Only the transcript and fixed Beauty & Cosmetology context ID reach the authenticated backend. The provider returns bounded structured text with storage disabled in the request. The phrase, repeat transcript and role-play reply stay in app memory while the screen is open; leaving clears them. A failed generation request preserves the take for retry. The feature does not store a phrase bank or assess pronunciation.

No background-recording capability is enabled. Active capture stops on app interruption/navigation and at 60 seconds. No learner audio is uploaded automatically. No analytics or learner-content logging are configured. Device TTS receives authored instructions, examples or a returned transcript; its installed voices may depend on the phone's speech engine and network availability.

## Permissions and backups

Android declares microphone and network permissions for optional speech uploads; it does not request external storage. Debug builds allow cleartext only for local development endpoints; release speech URLs must use HTTPS. Android application backup is disabled. iOS declares microphone and local-network purpose strings and does not enable background audio. Routine audio is in OS cache, not documents or a shared directory. Local SQLite preferences may participate in iOS device backups; they contain no voice or identity data.

Permission denial is recoverable via phone settings and Check permission again. Hardware permission revocation, phone calls, Bluetooth/wired audio, and screen readers must be checked on both actual platforms before a learner pilot.

## Secrets and deployment

There are no provider credentials in the mobile app. A pilot access code is entered at runtime and held in memory for the current app session. Environment files, signing credentials, local SDK paths and generated build output are ignored. The backend has no learner-data endpoints or remote database. `/health` exposes only a fixed service name, version and liveness. API docs are off unless explicitly enabled for local development. Release signing and production hosting are not configured.

The pilot bearer token protects internal test endpoints but is not per-learner authorization or a public abuse control. Do not expose this service publicly or place that token in a mobile build. Use proper learner authentication, rate limiting and transport protection before public deployment.

Before storing remote learner data or exposing the API publicly, implement learner authentication, per-learner authorization, rate limits, retention/deletion policies and transport protection. Use database migrations and row-level access controls when a shared data platform is introduced. These are future requirements, not completed pilot functionality.

## Local removal

Delete recording removes the current take. Relaunching the app clears previous takes automatically. The in-app **Privacy and phone data** screen offers a confirmed **Clear phone data** action. It discards current lesson, dialogue and assessment takes, removes staged baseline answers, clears transient transcript, feedback, dialogue and pilot code, deletes onboarding choices, all five saved prompt positions, daily attempt markers, salon reply counts, answer-recording time and word review timing in a SQLite transaction, and returns to Welcome. A failed audio or database operation reports retry rather than claiming success. This local action works offline and cannot revoke earlier provider processing or data in device backups. A learner-facing account/data deletion flow is required before public launch if accounts are introduced.
