# Alpha security and privacy

## Data handled

The app stores profession, English support choice, onboarding position and Day-1 phrase position in private SQLite storage. It does not persist names, accounts, transcripts, learning scores or cloud identifiers.

The microphone records only after an explicit learner action and OS permission. Mono audio is written to the app's private temporary cache. One current take is retained for in-app navigation. Starting a replacement, moving to another phrase, pressing Delete recording, or launching the app again removes it. The OS may evict cache files. A recording is not an English Mirror artefact or durable lesson history.

**Hear my words** is a separate learner action that uploads the current take to the SpeakCraft backend for transcription. The transcript stays in app memory with that take. The backend reads at most 4 MiB and stores neither audio nor transcript. The configured provider receives audio for transcription; review the provider account's retention and data-use settings before processing real learner recordings. A failed connection leaves the local take available for manual retry, but relaunch still clears it.

No background-recording capability is enabled. Active capture stops on app interruption/navigation and at 60 seconds. No learner audio is uploaded automatically. No analytics or learner-content logging are configured. Device TTS receives authored instructions, examples or a returned transcript; its installed voices may depend on the phone's speech engine and network availability.

## Permissions and backups

Android declares microphone and network permissions for optional speech uploads; it does not request external storage. Debug builds allow cleartext only for local development endpoints; release speech URLs must use HTTPS. Android application backup is disabled. iOS declares microphone and local-network purpose strings and does not enable background audio. Routine audio is in OS cache, not documents or a shared directory. Local SQLite preferences may participate in iOS device backups; they contain no voice or identity data.

Permission denial is recoverable via phone settings and Check permission again. Hardware permission revocation, phone calls, Bluetooth/wired audio, and screen readers must be checked on both actual platforms before a learner pilot.

## Secrets and deployment

There are no provider credentials in the mobile app. A pilot access code is entered at runtime and held in memory for the current app session. Environment files, signing credentials, local SDK paths and generated build output are ignored. The backend has no learner-data endpoints or remote database. `/health` exposes only a fixed service name, version and liveness. API docs are off unless explicitly enabled for local development. Release signing and production hosting are not configured.

The pilot bearer token protects an internal test endpoint but is not per-learner authorization or a public abuse control. Do not expose this service publicly or place that token in a mobile build. Use proper learner authentication, rate limiting and transport protection before public deployment.

Before storing remote learner data or exposing the API publicly, implement learner authentication, per-learner authorization, rate limits, retention/deletion policies and transport protection. Use database migrations and row-level access controls when a shared data platform is introduced. These are future requirements, not completed pilot functionality.

## Local removal

Delete recording removes the current take. Relaunching the app clears previous takes automatically. Resetting app storage on Android or deleting/reinstalling the app on iOS removes local practice state (subject to OS backups). A learner-facing account/data deletion flow is required before public launch if accounts are introduced.
