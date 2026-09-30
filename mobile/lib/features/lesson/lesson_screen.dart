import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../shared/components.dart';
import 'microphone_controller.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});
  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with WidgetsBindingObserver {
  late MicrophoneController _mic;
  @override
  void initState() {
    super.initState();
    _mic = ref.read(microphoneProvider);
    _mic.resume();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mic.resume();
    } else {
      unawaited(_mic.interrupt());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_mic.interrupt());
    super.dispose();
  }

  Future<void> _home() async {
    await _mic.interrupt();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final session = ref.watch(sessionProvider);
    final lesson = services.curriculum.dayOne;
    return ListenableBuilder(
      listenable: Listenable.merge([_mic, session]),
      builder: (context, _) {
        final index = session.progress.dayOnePrompt;
        final prompt = lesson.prompts[index];
        final (status, button, icon) = switch (_mic.state) {
          MicrophoneState.idle => (
            'Ready when you are.',
            'Enable microphone',
            Icons.mic_none,
          ),
          MicrophoneState.requestingPermission => (
            'Allow the microphone to practise speaking.',
            'Requesting permission…',
            Icons.mic_none,
          ),
          MicrophoneState.ready => (
            'Tap when you are ready to speak.',
            'Start recording',
            Icons.mic_none,
          ),
          MicrophoneState.recording => (
            'Recording. Tap stop when you finish.',
            'Stop recording',
            Icons.stop_circle_outlined,
          ),
          MicrophoneState.processing => (
            'Please wait…',
            'Please wait…',
            Icons.hourglass_top,
          ),
          MicrophoneState.success => (
            'Your recording is saved for this session. Speech feedback is not available yet.',
            'Try again',
            Icons.replay,
          ),
          MicrophoneState.failure => (
            "We couldn't save that recording. Please try again.",
            'Try microphone again',
            Icons.refresh,
          ),
          MicrophoneState.permissionDenied => (
            'Microphone access is off. Allow it in your phone settings, then try again.',
            'Check permission again',
            Icons.mic_off_outlined,
          ),
        };
        return PopScope(
          canPop: !_mic.capturing,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) unawaited(_home());
          },
          child: SpeakCraftPage(
            title: lesson.title,
            onBack: session.saving ? null : _home,
            children: [
              Text('Day 1 • Practice ${index + 1} of ${lesson.prompts.length}'),
              LinearProgressIndicator(
                value: (index + 1) / lesson.prompts.length,
                semanticsLabel:
                    'Practice ${index + 1} of ${lesson.prompts.length}',
              ),
              Text(
                prompt.instruction,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SpeakCraftAudioButton(
                text: prompt.instruction,
                label: 'Hear instructions',
                enabled: !_mic.capturing,
              ),
              SpeakCraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('EXAMPLE'),
                    const SizedBox(height: 12),
                    Text(
                      prompt.example,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    SpeakCraftAudioButton(
                      text: prompt.example,
                      label: 'Listen to example',
                      enabled: !_mic.capturing,
                    ),
                  ],
                ),
              ),
              const Text('Use your own details. It is okay to try again.'),
              SpeakCraftNotice(status, icon: icon, live: true),
              if (_mic.state == MicrophoneState.recording)
                const Text('Recording stops after 60 seconds.'),
              SpeakCraftButton(
                label: button,
                icon: icon,
                onPressed: _mic.busy || session.saving
                    ? null
                    : () async {
                        switch (_mic.state) {
                          case MicrophoneState.ready:
                            await _mic.start(prompt.id);
                          case MicrophoneState.recording:
                            await _mic.finish();
                          default:
                            await _mic.prepare();
                        }
                      },
              ),
              if (_mic.recordingPath != null)
                OutlinedButton.icon(
                  onPressed: _mic.capturing ? null : _mic.discard,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete recording'),
                ),
              const SpeakCraftNotice(
                'Your voice stays on this phone. Recordings are removed when you replace them or reopen the app.',
                icon: Icons.privacy_tip_outlined,
              ),
              if (session.error != null)
                SpeakCraftNotice(
                  session.error!,
                  icon: Icons.error_outline,
                  live: true,
                ),
              if (index < lesson.prompts.length - 1)
                OutlinedButton.icon(
                  onPressed: _mic.capturing || session.saving
                      ? null
                      : () async {
                          final saved = await session.update(
                            session.progress.copyWith(dayOnePrompt: index + 1),
                          );
                          if (saved) await _mic.discard();
                        },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(session.saving ? 'Saving…' : 'Next practice'),
                )
              else ...[
                const SpeakCraftNotice(
                  'Keep practising your introduction. We have not assessed or scored your speaking.',
                ),
                OutlinedButton.icon(
                  onPressed: _mic.capturing || session.saving
                      ? null
                      : () async {
                          final saved = await session.update(
                            session.progress.copyWith(dayOnePrompt: 0),
                          );
                          if (saved) await _mic.discard();
                        },
                  icon: const Icon(Icons.replay),
                  label: const Text('Practise from the start'),
                ),
              ],
              OutlinedButton.icon(
                onPressed: session.saving ? null : _home,
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        );
      },
    );
  }
}
