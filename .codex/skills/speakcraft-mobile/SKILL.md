---
name: speakcraft-mobile
description: Build or review SpeakCraft Flutter screens, navigation, accessibility, voice interactions, offline behaviour, responsive layouts, and cross-platform Android/iOS mobile functionality.
---

# SpeakCraft Mobile Skill

Use for Flutter/mobile implementation.

## Target

One shared Flutter codebase supporting Android and iOS.

## UX priority

The learner may have limited English literacy.

Prefer:

- large touch targets;
- minimal text;
- strong hierarchy;
- audio guidance;
- text + icon rather than unexplained icons;
- predictable interactions;
- visible microphone state;
- obvious retry actions.

## Voice states

Every microphone interaction must account for:

- idle
- requesting permission
- ready
- recording
- processing
- success
- retry
- permission denied
- network unavailable
- unexpected failure

Do not leave microphone state ambiguous.

## Connectivity

Never discard completed learner work because connectivity changes.

Where possible:

local write
→ UI confirmation
→ background/next-opportunity sync

## Cross-platform

For every feature, consider:

- Android permissions
- iOS permissions
- lifecycle changes
- microphone interruptions
- Bluetooth/wired audio
- small displays
- keyboard overlap
- accessibility scaling

## Components

Prefer reusable SpeakCraft components rather than one-off screen styling.

Examples:

SpeakCraftButton
SpeakCraftCard
SpeakCraftMicButton
SpeakCraftAudioButton
SpeakCraftProgressBar
SpeakCraftLessonCard
SpeakCraftFeedbackCard
SpeakCraftOfflineBanner

## Accessibility

Use semantic labels.

Ensure adequate touch targets.

Do not communicate important state using colour alone.

Support text scaling where practical.

## Loading

Avoid blocking the entire interface unnecessarily.

Voice/AI processing must have obvious progress feedback.

## Error messages

Use learner-friendly language.

Preserve technical error details for logs, not learner UI.

## Testing

Include widget/unit tests where useful.

Critical journeys should eventually have integration coverage.

Never mark a mobile feature complete without considering both Android and iOS.
