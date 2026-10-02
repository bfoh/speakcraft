import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../shared/components.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculum = ref.watch(servicesProvider).curriculum;
    final session = ref.watch(sessionProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, child) => SpeakCraftPage(
        title: 'My practice',
        onBack: () => context.pop(),
        children: [
          const SpeakCraftAudioButton(
            text: 'Your place is saved on this phone. Choose a day to keep practising.',
          ),
          const SpeakCraftNotice(
            'This shows where to continue. It is not a speaking score.',
          ),
          for (final lesson in curriculum.lessons)
            SpeakCraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Day ${lesson.day}: ${lesson.title}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Practice ${session.progress.promptForDay(lesson.day) + 1} of ${lesson.prompts.length}',
                  ),
                  const SizedBox(height: 16),
                  SpeakCraftButton(
                    label: 'Open Day ${lesson.day}',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.push('/lesson/day-${lesson.day}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
