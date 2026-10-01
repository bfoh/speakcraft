# SpeakCraft mobile

Shared Flutter Android/iOS application. See the repository README for pinned prerequisites, run commands and validation.

Feature modules own learner-facing flows. Core interfaces isolate storage, curriculum, microphone, speech recognition and teaching feedback. Tests use explicit fakes; production uses native recording, SQLite and SpeakCraft HTTP clients. No provider credential or provider-specific SDK is present in Flutter. Supply a nonsecret `SPEAKCRAFT_API_BASE_URL` at run time to enable **Hear my words** and **Help me say it better**; a facilitator enters the pilot access code inside the app, where it remains in memory for that session.
