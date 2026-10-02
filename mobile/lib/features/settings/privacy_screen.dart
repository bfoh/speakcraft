import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../shared/components.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _clearing = false;
  String? _error;

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear phone data?'),
        content: const Text(
          'This erases your choices, saved speaking steps, salon reply counts and recording time, word reviews and current recordings on this phone. You will start again at Welcome.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep my data'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear phone data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _clearing = true;
      _error = null;
    });
    final lessonMic = ref.read(microphoneProvider);
    final dialogueMic = ref.read(conversationMicrophoneProvider);
    final assessmentMic = ref.read(assessmentMicrophoneProvider);
    final assessment = ref.read(assessmentProvider);
    final assessmentPlayback = ref.read(assessmentPlaybackProvider);
    final transcription = ref.read(transcriptionProvider);
    final feedback = ref.read(feedbackProvider);
    final conversation = ref.read(conversationProvider);
    final expression = ref.read(expressionProvider);
    final curriculum = ref.read(servicesProvider).curriculum;
    final salonConversations = [
      for (final scenario in curriculum.salonScenarios)
        ref.read(salonConversationProvider(scenario.id)),
    ];
    final session = ref.read(sessionProvider);
    final review = ref.read(reviewProvider);

    if (!await assessmentPlayback.stop()) {
      if (mounted) {
        setState(() {
          _clearing = false;
          _error = "We couldn't stop an answer. Please try again.";
        });
      }
      return;
    }

    // Attempt every recorder even when one fails. Durable data is cleared only
    // after all recorders and staged baseline takes are gone.
    final lessonCleared = await lessonMic.clearForPrivacy();
    final dialogueCleared = await dialogueMic.clearForPrivacy();
    final assessmentMicCleared = await assessmentMic.clearForPrivacy();
    if (!lessonCleared || !dialogueCleared || !assessmentMicCleared) {
      if (mounted) {
        setState(() {
          _clearing = false;
          _error = "We couldn't clear a recording. Please try again.";
        });
      }
      return;
    }
    if (!await assessment.clear()) {
      if (mounted) {
        setState(() {
          _clearing = false;
          _error = assessment.error;
        });
      }
      return;
    }

    transcription.clearAccessToken();
    transcription.clear();
    feedback.clear();
    conversation.reset();
    expression.reset();
    for (final salon in salonConversations) {
      salon.reset();
    }
    await review.settleWrites();
    final cleared = await session.reset();
    if (cleared) review.clearLocal();
    if (!mounted) return;
    if (cleared) {
      context.go('/welcome');
    } else {
      setState(() {
        _clearing = false;
        _error = session.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SpeakCraftPage(
    title: 'Privacy and phone data',
    onBack: _clearing ? null : () => context.pop(),
    children: [
      const SpeakCraftAudioButton(
        text: 'Your choices, speaking steps, salon reply counts and recording time stay on this phone. You choose when to send a recording or words for help. You can clear phone data here.',
      ),
      const SpeakCraftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Saved on this phone'),
            SizedBox(height: 8),
            Text(
              'Your course, place in each day, recorded speaking steps, salon reply counts and recording time, and word review schedule. Starting assessment recordings are removed at next launch or when you clear phone data.',
            ),
            SizedBox(height: 16),
            Text('Sent only when you choose'),
            SizedBox(height: 8),
            Text(
              'A recording goes to the speech service when you tap Hear my words. Your words go to Kora when you ask for help or send a reply.',
            ),
          ],
        ),
      ),
      const SpeakCraftNotice(
        'Clearing this phone does not undo earlier requests sent to the speech service.',
      ),
      if (_error != null)
        SpeakCraftNotice(_error!, icon: Icons.error_outline, live: true),
      SpeakCraftButton(
        label: _clearing ? 'Clearing phone data' : 'Clear phone data',
        icon: Icons.delete_outline,
        onPressed: _clearing ? null : _clear,
      ),
    ],
  );
}
