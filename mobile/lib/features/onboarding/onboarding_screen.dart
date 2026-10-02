import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../core/storage/progress_store.dart';
import '../../shared/components.dart';

const onboardingPaths = [
  '/welcome',
  '/profession',
  '/language',
  '/kora',
  '/assessment',
];

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, required this.step});
  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final (title, message, action, icon) = switch (step) {
      0 => (
        'Real English.\nReal skills.',
        'Practise English for your work. Listen, speak and try again.',
        'Get started',
        Icons.waving_hand_outlined,
      ),
      1 => (
        'What do you study?',
        'Practise the conversations you need at work.',
        'Continue',
        Icons.content_cut,
      ),
      2 => (
        'Choose your support language',
        'We will guide you in English.',
        'Continue in English',
        Icons.language,
      ),
      3 => (
        'Meet Kora',
        "I'm Kora, your AI English tutor. We will practise one step at a time. You can try again.",
        'Meet your first lesson',
        Icons.chat_bubble_outline,
      ),
      _ => (
        'Let’s begin gently',
        'You can record a starting sample, then practise Day 1. No score is available yet.',
        'Go to Home',
        Icons.record_voice_over,
      ),
    };
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => SpeakCraftPage(
        title: title,
        onBack: step == 0 || session.saving
            ? null
            : () => context.go(onboardingPaths[step - 1]),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(radius: 36, child: Icon(icon, size: 36)),
          ),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          SpeakCraftAudioButton(
            text:
                '$title. $message${step == 4 ? ' Open the starting assessment from Home.' : ''}',
          ),
          if (step == 1)
            const SpeakCraftCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Beauty & Cosmetology\nYour Alpha pathway'),
                  ),
                ],
              ),
            ),
          if (step == 2) ...[
            const SpeakCraftCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 12),
                  Expanded(child: Text('English')),
                ],
              ),
            ),
            const SpeakCraftNotice(
              'Twi, Ga and Ewe support is not available yet.',
            ),
          ],
          if (step == 3)
            const SpeakCraftNotice(
              'From Home, you can practise a short conversation with Kora. Record and send each reply when you are ready.',
            ),
          if (step == 4)
            const SpeakCraftNotice(
              'Open Starting assessment from Home. Your recordings stay only for this app session. No result is recorded yet.',
            ),
          if (session.error != null)
            SpeakCraftNotice(
              session.error!,
              icon: Icons.error_outline,
              live: true,
            ),
          SpeakCraftButton(
            label: session.saving ? 'Saving…' : action,
            icon: Icons.arrow_forward,
            onPressed: session.saving
                ? null
                : () async {
                    final nextStep = (step + 1).clamp(
                      session.progress.onboardingStep,
                      5,
                    );
                    final LearnerProgress next = session.progress.copyWith(
                      onboardingStep: nextStep,
                      profession: step == 1 ? 'beauty-cosmetology' : null,
                      supportLanguage: step == 2 ? 'en' : null,
                    );
                    final saved = await session.update(next);
                    if (saved && context.mounted) {
                      context.go(
                        step == 4 ? '/home' : onboardingPaths[step + 1],
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
