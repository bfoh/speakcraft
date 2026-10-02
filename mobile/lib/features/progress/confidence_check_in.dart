import 'package:flutter/material.dart';

import '../../core/storage/progress_store.dart';
import '../../shared/components.dart';

const confidenceQuestion =
    'How ready do you feel to help a customer in English today?';

const confidenceLabels = <String>[
  'Not ready yet',
  'A little ready',
  'Somewhat ready',
  'Ready',
  'Very ready',
];

String confidenceLabel(int rating) =>
    '$rating — ${confidenceLabels[rating - 1]}';

class ConfidenceCheckInCard extends StatelessWidget {
  const ConfidenceCheckInCard({
    super.key,
    required this.current,
    required this.saving,
    required this.onSelected,
    this.error,
    this.enabled = true,
  });

  final ConfidenceCheckIn? current;
  final bool saving;
  final ValueChanged<int> onSelected;
  final String? error;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SpeakCraftCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(confidenceQuestion, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Your own feeling. This is not a speaking score.'),
        const SizedBox(height: 12),
        SpeakCraftAudioButton(
          text:
              '$confidenceQuestion Choose from one, not ready yet, to five, very ready.',
          label: 'Hear the question',
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        for (var rating = 1; rating <= 5; rating++) ...[
          Semantics(
            selected: current?.rating == rating,
            child: OutlinedButton.icon(
              onPressed: saving || !enabled ? null : () => onSelected(rating),
              icon: Icon(
                current?.rating == rating
                    ? Icons.check_circle_outline
                    : Icons.circle_outlined,
              ),
              label: Text(confidenceLabel(rating)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (saving) const SpeakCraftNotice('Saving your choice…', live: true),
        if (current != null)
          SpeakCraftNotice(
            'Saved on this phone: ${confidenceLabel(current!.rating)}.',
            icon: Icons.check_circle_outline,
            live: true,
          ),
        if (error != null)
          SpeakCraftNotice(error!, icon: Icons.error_outline, live: true),
      ],
    ),
  );
}
