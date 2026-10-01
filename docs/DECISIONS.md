# SpeakCraft decisions

## 2026-09-29 — Sprint 1 scope

The user explicitly requests a foundation and beginning of Day 1. Implement blueprint section 31 Sprint 1, deferring section 35's full customer/transcription slice. Assessment execution, live Kora, AI feedback, and speech APIs remain absent. Record confirmation never claims successful communication.

## 2026-09-29 — Shared Flutter application

Use Riverpod and GoRouter, following the recommended blueprint stack. Keep presentation inside features, adapters in core, and composition in app. Small ChangeNotifier controllers avoid code generation for the current scope. Use sqflite directly as the blueprint's SQLite equivalent; Drift is unnecessary for one small record. Schema version 1 creates the local progress table; subsequent changes need migrations.

Native simulator launch exposed a scoped Riverpod dependency error that root-override widget tests missed. The bootstrap's services, dependent controllers and router now declare scoped dependencies. A production-bootstrap widget test guards this composition path.

## 2026-09-29 — Authored curriculum packaging

Keep the five-day Alpha in canonical versioned JSON, validate it, and package a byte-identical mobile asset. Only Day 1 is navigable. The five-day sequence supersedes the thirty-day curriculum for Alpha. Example phrases are editorial additions aligned to the blueprint and require educator review.

## 2026-09-29 — Honest local voice practice

Use real native recording via an interface. Request microphone permission at the point of use. Bound capture to 60 seconds and stop on interruptions. Retain one take in private cache for the running session and delete on replacement, discard, phrase change or next launch. This is not English Mirror, durable recording storage, transcription, or AI evaluation.

Device text-to-speech makes authored instructions and examples audible without an AI integration. Its availability depends on installed voices; display useful fallback text. The voice does not establish a required learner accent.

## 2026-09-29 — Support language

Only English is selectable because no reviewed Twi, Ga or Ewe text/voice assets exist. Explain this on the support-language screen. Do not save a choice that has no working support. Kora is identified as AI, with live interaction explicitly unavailable.

## 2026-09-29 — Minimal backend

A FastAPI factory and typed liveness endpoint establish a testable API skeleton without speculative databases, auth stubs or services. Environment configuration controls local interactive docs, off by default. The mobile sprint remains runnable without this process.

## 2026-09-29 — Toolchain and distribution

Pin Flutter 3.47.5/Dart 3.13.4. Android minimum API 24, compile/target 36, Java 17; iOS minimum 15. Generated personal signing-team settings are removed. No production signing credentials or debug-signed release configuration is committed. Host test/build toolchains live outside the repository.

## 2026-10-01 — Explicit speech transcription

Use the blueprint's completed-file transcription step before teaching feedback. Mobile calls only `POST /v1/speech/transcribe`; the provider-specific request and key remain on FastAPI. A transcript is shown as tentative words, never a communication score. The learner separately chooses recording and upload. Failed uploads leave the take available for manual retry; no automatic background upload occurs.

Require a server-side provider key and long pilot bearer token. A facilitator enters the pilot code at runtime in the app; it is held only in memory. This is restricted to local/internal testing. Public access needs learner authentication, rate limits and reviewed provider retention. No live provider call was verified without a key.

## 2026-10-01 — Prompt-bound teaching feedback

The learner requests feedback only after seeing the tentative transcript. The backend loads lesson objectives from the canonical curriculum and refuses client-authored objectives. OpenAI Responses produces strict structured output with `store: false`; application validation bounds fields and rejects malformed feedback. Text-only feedback gives no pronunciation or numerical score. Feedback is ephemeral in the mobile app, and a failed request preserves the take and transcript. No live model or educator review was possible without a server key and consented learner samples.

## 2026-10-02 — Bounded Kora conversation

Apply the Day-1 introduction in a three-turn dialogue before adding AI Salon. Keep the opening, goal and success conditions in authored curriculum. Use a stateless backend request with bounded recent turns, provider-neutral structured output and no stored conversation. The learner reviews a tentative transcript and explicitly sends each reply. Device speech reads Kora's words. This design is slower than streaming voice but preserves the explicit privacy and recovery controls already used in practice.

## 2026-10-02 — First AI Salon scenario

Add only the blueprint's first difficulty-1 customer: friendly, interested in braids and asking about price. Keep every scenario boundary in canonical curriculum. Reuse the explicit voice-dialogue UI, while the API adapter maps partner turns to customer/learner roles. The backend uses a stateless `POST /v1/salon/respond` contract because there is no durable session or assessment store yet. It returns a customer reply without a success score and asks the provider not to invent a real salon price.
