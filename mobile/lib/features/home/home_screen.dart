import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../shared/components.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculum = ref.watch(servicesProvider).curriculum;
    final session = ref.watch(sessionProvider);
    final dayOne = curriculum.dayOne;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final progress = session.progress;
        return SpeakCraftPage(
          title: 'Ready to speak?',
          children: [
            const Text('A little practice, one step at a time.'),
            const SpeakCraftAudioButton(
              text: 'Ready to speak? Start Day 1. Practise telling someone about yourself.',
            ),
            SpeakCraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('STARTING ASSESSMENT'),
                  const SizedBox(height: 12),
                  Text(
                    'Record a starting sample across five short tasks.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No score yet. Recordings last for this app session.',
                  ),
                  const SizedBox(height: 20),
                  SpeakCraftButton(
                    label: 'Open starting assessment',
                    icon: Icons.assignment_outlined,
                    onPressed: () => context.push('/baseline'),
                  ),
                ],
              ),
            ),
            SpeakCraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('DAY 1 • BEAUTY & COSMETOLOGY'),
                  const SizedBox(height: 12),
                  Text(
                    dayOne.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(dayOne.objective),
                  const SizedBox(height: 8),
                  Text(
                    progress.finishedPractice(dayOne.prompts.map((p) => p.id))
                        ? 'Practice steps finished'
                        : '${progress.attemptedCount(dayOne.prompts.map((p) => p.id))} of ${dayOne.prompts.length} speaking steps saved',
                  ),
                  const SizedBox(height: 20),
                  SpeakCraftButton(
                    label: 'Open Day 1',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.push('/lesson/day-1'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/conversation/day-1'),
                    icon: const Icon(Icons.record_voice_over_outlined),
                    label: const Text('Talk with Kora'),
                  ),
                ],
              ),
            ),
            SpeakCraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('AI SALON • FIRST CUSTOMER'),
                  const SizedBox(height: 12),
                  Text(
                    curriculum.firstSalonScenario.scenarioGoal,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text('Practise with a simulated customer.'),
                  const SizedBox(height: 20),
                  SpeakCraftButton(
                    label: 'Open AI Salon',
                    icon: Icons.storefront_outlined,
                    onPressed: () => context.push('/salon/first'),
                  ),
                ],
              ),
            ),
            SpeakCraftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('HELP ME SAY IT'),
                  const SizedBox(height: 12),
                  Text(
                    'Find useful English for something you want to tell a customer.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  SpeakCraftButton(
                    label: 'Open Help Me Say It',
                    icon: Icons.lightbulb_outline,
                    onPressed: () => context.push('/help-me-say-it'),
                  ),
                ],
              ),
            ),
            const SpeakCraftNotice(
              'Your place is saved on this phone. You can practise without internet.',
              icon: Icons.offline_pin_outlined,
            ),
            SpeakCraftButton(
              label: 'My practice',
              icon: Icons.route_outlined,
              onPressed: () => context.push('/progress'),
            ),
            SpeakCraftButton(
              label: 'My Words',
              icon: Icons.record_voice_over_outlined,
              onPressed: () => context.push('/review'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings/privacy'),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: const Text('Privacy and phone data'),
            ),
            Semantics(
              header: true,
              child: Text(
                'Your five-day journey',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final lesson in curriculum.lessons.skip(1))
              SpeakCraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Day ${lesson.day}: ${lesson.title}'),
                              const SizedBox(height: 8),
                              Text(lesson.objective),
                              const SizedBox(height: 8),
                              Text(
                                'Practice ${progress.promptForDay(lesson.day) + 1} of ${lesson.prompts.length}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                progress.finishedPractice(
                                      lesson.prompts.map((p) => p.id),
                                    )
                                    ? 'Practice steps finished'
                                    : '${progress.attemptedCount(lesson.prompts.map((p) => p.id))} of ${lesson.prompts.length} speaking steps saved',
                              ),
                              if (lesson.day == 3 || lesson.day == 5) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'AI Salon replies saved: ${progress.bestSalonTurns(curriculum.scenarioForDay(lesson.day)!.id)} of ${curriculum.scenarioForDay(lesson.day)!.turnLimit}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Most time recording answers: ${progress.longestSalonRecordedSeconds(curriculum.scenarioForDay(lesson.day)!.id)} seconds',
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Guided practice. Full challenge is not assessed here.',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SpeakCraftButton(
                      label: 'Open Day ${lesson.day}',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () =>
                          context.push('/lesson/day-${lesson.day}'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
