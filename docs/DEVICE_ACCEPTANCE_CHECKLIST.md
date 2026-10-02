# Final connected-device acceptance checklist

**Do this last.** This is a future test sheet; no physical-device result has been recorded. Use one representative Android phone and one iPhone, noting device model, OS version, app commit, installed English voice, connection type and audio route. Use non-sensitive test speech unless a consented study protocol is in place.

## Preparation

1. Confirm content, consent/provider and pilot gates in [PILOT_READINESS.md](PILOT_READINESS.md). Keep the backend on an internal network until per-learner controls exist.
2. Connect and unlock each device; trust the development computer, allow Android debugging or set an iOS development signing team as appropriate. From `mobile/`, run `flutter devices` to record both device IDs.
3. Run `flutter doctor -v`. Build and install the app on each target with `flutter run -d <device-id>`. For internal backend calls, use the device-reachable HTTPS SpeakCraft URL with `--dart-define=SPEAKCRAFT_API_BASE_URL=<https-url>` and enter the pilot code only at runtime. Never embed a provider key or shared code in the app build.
4. Start each case from a known state and record outcome, screenshot/log location without learner content, and any cleanup required. Do not mark a case passed on one platform because it passed on the other.

## Both-platform matrix

| Case | Expected observation | Android | iOS |
| --- | --- | --- | --- |
| Welcome through Home | Profession, support language, Kora intro and assessment intro are readable and spoken where offered; navigation remains clear | pending | pending |
| Days 1–5 offline | Instructions/examples play when a local voice is available; speaking-step markers and position survive relaunch; connection loss does not remove a take | pending | pending |
| Starting and Day-5 fixed tasks | Each prompt is heard, recorded, replayed and cleared; staged answers stay separate, expire on relaunch and receive no score | pending | pending |
| Microphone permission | First allow, deny, deny permanently/revoke in settings, and retry show accurate state and recovery | pending | pending |
| Audio routes | Built-in speaker/mic, wired headset and Bluetooth; check recording input and spoken output route | pending | pending |
| Interruptions | Incoming call/assistant, app background, screen lock and audio focus change stop capture or playback safely; no falsely saved answer | pending | pending |
| Low-literacy accessibility | 200% text, small display, screen reader labels/order, touch targets, visible microphone state and non-colour feedback | pending | pending |
| Backend retry | With a configured internal server, test transcript, Kora, Help Me Say It and AI Salon; turn off network mid-request, restore and retry without losing the take | pending | pending |
| Privacy reset | Confirm dialog; active playback stops; local audio, progress, self-ratings and word reviews clear; failed deletion offers retry | pending | pending |
| Day-3 consultation | Record the customer/learner timing events proposed in [the measurement protocol](CONSULTATION_MEASUREMENT.md); do not declare the 90-second goal met from microphone time | pending | pending |

## Exit rule

For each case, record **pass / fail / blocked**, the device and OS, reproducible steps, expected and actual behavior, and the fix verification. Resolve critical recording loss, privacy, permission, route, accessibility and network-retry failures on both platforms before a learner pilot. A working simulator build or widget test does not replace this sheet.
