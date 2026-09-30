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
    final dayOne = curriculum.dayOne;
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
              const Text('DAY 1 • BEAUTY & COSMETOLOGY'),
              const SizedBox(height: 12),
              Text(
                dayOne.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(dayOne.objective),
              const SizedBox(height: 20),
              SpeakCraftButton(
                label: 'Open Day 1',
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push('/lesson/day-1'),
              ),
            ],
          ),
        ),
        const SpeakCraftNotice(
          'Your place is saved on this phone. You can practise without internet.',
          icon: Icons.offline_pin_outlined,
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
            child: Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day ${lesson.day}: ${lesson.title}'),
                      const Text('Coming later'),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
