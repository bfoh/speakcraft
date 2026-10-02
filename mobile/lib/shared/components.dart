import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../core/audio/speech_output.dart';

class SpeakCraftPage extends StatelessWidget {
  const SpeakCraftPage({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('SpeakCraft'),
      automaticallyImplyLeading: false,
      leading: onBack == null
          ? null
          : IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SpeakCraftTheme.space),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final child in children) ...[
                    child,
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class SpeakCraftButton extends StatelessWidget {
  const SpeakCraftButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class SpeakCraftCard extends StatelessWidget {
  const SpeakCraftCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class SpeakCraftNotice extends StatelessWidget {
  const SpeakCraftNotice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.live = false,
  });
  final String text;
  final IconData icon;
  final bool live;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: live,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class SpeakCraftAudioButton extends ConsumerStatefulWidget {
  const SpeakCraftAudioButton({
    super.key,
    required this.text,
    this.label = 'Listen',
    this.enabled = true,
  });
  final String text;
  final String label;
  final bool enabled;
  @override
  ConsumerState<SpeakCraftAudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends ConsumerState<SpeakCraftAudioButton> {
  bool _playing = false;
  late final SpeechOutput _speech;

  @override
  void initState() {
    super.initState();
    _speech = ref.read(servicesProvider).speech;
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _speech.stop();
      return;
    }
    setState(() => _playing = true);
    try {
      await _speech.speak(widget.text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Audio isn't available. Check your phone's English voice settings, or use the words on screen.",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  void dispose() {
    // Route changes stop instructions so they cannot leak into a recording.
    if (_playing) {
      unawaited(_speech.stop().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: widget.enabled ? _toggle : null,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_playing ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
        const SizedBox(width: 12),
        Flexible(child: Text(_playing ? 'Stop audio' : widget.label)),
      ],
    ),
  );
}
