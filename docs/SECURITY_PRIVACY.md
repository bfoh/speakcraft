# Sprint 1 security and privacy

## Data handled

The app stores profession, English support choice, onboarding position and Day-1 phrase position in private SQLite storage. It does not collect names, accounts, transcripts, learning scores or cloud identifiers.

The microphone records only after an explicit learner action and OS permission. Mono audio is written to the app's private temporary cache. One current take is retained for in-app navigation. Starting a replacement, moving to another phrase, pressing Delete recording, or launching the app again removes it. The OS may evict cache files. A recording is not an English Mirror artefact or durable lesson history.

No background-recording capability is enabled. Active capture stops on app interruption/navigation and at 60 seconds. No learner audio is uploaded. No analytics or learner-content logging are configured. Device TTS receives only authored examples/instructions; its installed voices may depend on the phone's speech engine and network availability.

## Permissions and backups

Android declares only recording permission in the release manifest; it does not request external storage or networking for current lesson work. Debug/profile manifests allow internet for Flutter development tooling. Android application backup is disabled. iOS declares a clear microphone purpose string and does not enable background audio. Routine audio is in OS cache, not documents or a shared directory. Local SQLite preferences may participate in iOS device backups; they contain no voice or identity data.

Permission denial is recoverable via phone settings and Check permission again. Hardware permission revocation, phone calls, Bluetooth/wired audio, and screen readers must be checked on both actual platforms before a learner pilot.

## Secrets and deployment

There are no provider credentials in the mobile app. Environment files, signing credentials, local SDK paths and generated build output are ignored. The backend has no learner-data endpoints or remote database. `/health` exposes only a fixed service name, version and liveness. API docs are off unless explicitly enabled for local development. Release signing and production hosting are not configured.

Before adding remote learner data, implement authentication, per-learner authorization, bounded input validation, retention/deletion policies and transport protection. Use database migrations and row-level access controls when the data platform is introduced. These are future requirements, not completed Sprint 1 functionality.

## Local removal

Delete recording removes the current take. Relaunching the app clears previous takes automatically. Resetting app storage on Android or deleting/reinstalling the app on iOS removes local practice state (subject to OS backups). A learner-facing account/data deletion flow is required before public launch if accounts are introduced.
