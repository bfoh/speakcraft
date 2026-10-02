import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../shared/components.dart';
import 'confidence_check_in.dart';

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
            'Finished means you recorded every speaking step. It is not a speaking score.',
          ),
          Text(
            '${curriculum.lessons.where((lesson) => session.progress.finishedPractice(lesson.prompts.map((p) => p.id))).length} of ${curriculum.lessons.length} days of guided practice finished',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (session.progress.confidenceCheckIns.isNotEmpty)
            SpeakCraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'How ready I felt',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('My own choices. These are not speaking scores.'),
                  if (session.progress.confidenceFor('starting')
                      case final start?)
                    Text('Starting: ${confidenceLabel(start.rating)}'),
                  if (session.progress.confidenceFor('day5') case final day5?)
                    Text('Day 5: ${confidenceLabel(day5.rating)}'),
                ],
              ),
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
                  const SizedBox(height: 8),
                  Text(
                    session.progress.finishedPractice(
                          lesson.prompts.map((p) => p.id),
                        )
                        ? 'Practice steps finished'
                        : '${session.progress.attemptedCount(lesson.prompts.map((p) => p.id))} of ${lesson.prompts.length} speaking steps saved',
                  ),
                  if (lesson.day == 3 || lesson.day == 5) ...[
                    const SizedBox(height: 8),
                    Text(
                      'AI Salon replies saved: ${session.progress.bestSalonTurns(curriculum.scenarioForDay(lesson.day)!.id)} of ${curriculum.scenarioForDay(lesson.day)!.turnLimit}',
                    ),
                    Text(
                      'Most time recording answers: ${session.progress.longestSalonRecordedSeconds(curriculum.scenarioForDay(lesson.day)!.id)} seconds',
                    ),
                  ],
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
