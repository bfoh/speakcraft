import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../core/curriculum/curriculum.dart';
import '../../core/storage/review_store.dart';
import '../../shared/components.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _showAll = false;
  int _allIndex = 0;

  Future<void> _rate(ReviewItem item, ReviewRating rating) async {
    final controller = ref.read(reviewProvider);
    final saved = await controller.rate(item, rating);
    if (saved && mounted && _showAll) {
      setState(() {
        _allIndex = (_allIndex + 1) % controller.items.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(reviewProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (!controller.loaded) {
          return SpeakCraftPage(
            title: 'My Words',
            onBack: () => context.pop(),
            children: [
              if (controller.loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                SpeakCraftNotice(
                  controller.error ?? "We couldn't open your words.",
                  icon: Icons.error_outline,
                  live: true,
                ),
                SpeakCraftButton(
                  label: 'Try again',
                  icon: Icons.refresh,
                  onPressed: () => unawaited(controller.load()),
                ),
              ],
            ],
          );
        }
        final due = controller.dueItems();
        final items = _showAll ? controller.items : due;
        final selected = items.isEmpty
            ? null
            : _showAll
            ? items[_allIndex % items.length]
            : items.first;
        return SpeakCraftPage(
          title: 'My Words',
          onBack: () => context.pop(),
          children: [
            const SpeakCraftAudioButton(
              text: 'Listen to a phrase. Say it aloud. Then choose if you need more practice or if it felt easy.',
            ),
            const SpeakCraftNotice(
              'Your choice sets the next review. It is not a speaking score.',
            ),
            Text(
              '${due.length} ${due.length == 1 ? 'word or phrase' : 'words or phrases'} to review now',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (selected == null)
              const SpeakCraftNotice(
                'All done for now. You can practise every word again whenever you like.',
                icon: Icons.check_circle_outline,
              )
            else
              _ReviewCard(
                item: selected,
                saving: controller.saving,
                onRate: _rate,
              ),
            if (controller.error != null)
              SpeakCraftNotice(
                controller.error!,
                icon: Icons.error_outline,
                live: true,
              ),
            SpeakCraftButton(
              label: _showAll ? 'Show words due now' : 'Show all words',
              icon: _showAll ? Icons.schedule : Icons.list_alt_outlined,
              onPressed: () => setState(() {
                _showAll = !_showAll;
                _allIndex = 0;
              }),
            ),
            if (_showAll && items.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _allIndex = (_allIndex + 1) % items.length;
                }),
                icon: const Icon(Icons.skip_next_outlined),
                label: const Text('Next word'),
              ),
          ],
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.item,
    required this.saving,
    required this.onRate,
  });
  final ReviewItem item;
  final bool saving;
  final Future<void> Function(ReviewItem, ReviewRating) onRate;

  @override
  Widget build(BuildContext context) => SpeakCraftCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Day ${item.day} • ${item.cue}'),
        const SizedBox(height: 12),
        Text(item.text, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        SpeakCraftAudioButton(text: item.text, label: 'Listen to phrase'),
        const SizedBox(height: 16),
        SpeakCraftButton(
          label: saving ? 'Saving…' : 'More practice',
          icon: Icons.replay_outlined,
          onPressed: saving
              ? null
              : () => unawaited(onRate(item, ReviewRating.morePractice)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: saving
              ? null
              : () => unawaited(onRate(item, ReviewRating.feltEasy)),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Felt easy'),
        ),
      ],
    ),
  );
}
