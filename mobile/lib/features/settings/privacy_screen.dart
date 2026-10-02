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
          'This erases your choices, saved practice places and current recordings on this phone. You will start again at Welcome.',
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

    // Attempt both caches even when one fails. Durable data is cleared only
    // after both recorders confirm that their current take is gone.
    final lessonCleared = await lessonMic.clearForPrivacy();
    final dialogueCleared = await dialogueMic.clearForPrivacy();
    if (!lessonCleared || !dialogueCleared) {
      if (mounted) {
        setState(() {
          _clearing = false;
          _error = "We couldn't clear a recording. Please try again.";
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
    final cleared = await session.reset();
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
        text: 'Your choices and practice place stay on this phone. You choose when to send a recording or words for help. You can clear phone data here.',
      ),
      const SpeakCraftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Saved on this phone'),
            SizedBox(height: 8),
            Text('Your course choice and place in each day.'),
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
