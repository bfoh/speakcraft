import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../features/lesson/microphone_controller.dart';
import '../../shared/components.dart';
import 'assessment_controller.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen>
    with WidgetsBindingObserver {
  late final MicrophoneController _mic;
  late final AssessmentController _assessment;
  String? _cleanupError;

  @override
  void initState() {
    super.initState();
    _mic = ref.read(assessmentMicrophoneProvider);
    _assessment = ref.read(assessmentProvider);
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

  Future<void> _home() async {
    if (_assessment.saving) return;
    await _mic.interrupt();
    if (mounted) context.go('/home');
  }

  Future<void> _saveAndContinue() async {
    final item = _assessment.current;
    final path = _mic.recordingPath;
    if (item == null || path == null || _mic.promptId != item.id) return;
    final saved = await _assessment.saveCurrent(path);
    if (!saved) return;
    await _mic.discard();
    if (_mic.state == MicrophoneState.failure && mounted) {
      setState(() {
        _cleanupError = "Your answer was saved, but the old take couldn't be removed. Try the microphone again.";
      });
    } else if (mounted) {
      setState(() => _cleanupError = null);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear starting recordings?'),
        content: const Text(
          'This removes all answers from this phone. You can start again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep recordings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear recordings'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final microphoneCleared = await _mic.clearForPrivacy();
    if (!microphoneCleared) {
      if (mounted) {
        setState(
          () => _cleanupError =
              "We couldn't clear a recording. Please try again.",
        );
      }
      return;
    }
    final cleared = await _assessment.clear();
    _mic.resume();
    if (cleared && mounted) {
      setState(() => _cleanupError = null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_mic.interrupt());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_assessment, _mic]),
    builder: (context, _) {
      final item = _assessment.current;
      if (item == null) {
        return SpeakCraftPage(
          title: 'Starting assessment',
          onBack: _home,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            Text(
              '${_assessment.capturedCount} recordings captured',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SpeakCraftNotice(
              'No score or assessment result is available yet. These recordings stay on this phone only for this app session and are removed next time you open the app.',
            ),
            if (_cleanupError != null)
              SpeakCraftNotice(
                _cleanupError!,
                icon: Icons.error_outline,
                live: true,
              ),
            if (_assessment.error != null)
              SpeakCraftNotice(
                _assessment.error!,
                icon: Icons.error_outline,
                live: true,
              ),
            SpeakCraftButton(
              label: 'Go to Home',
              icon: Icons.home_outlined,
              onPressed: _home,
            ),
            OutlinedButton.icon(
              onPressed: _assessment.saving ? null : _clear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear these recordings'),
            ),
          ],
        );
      }
      final ownsTake = _mic.promptId == item.id;
      final (status, action, icon) = switch (_mic.state) {
        MicrophoneState.idle => (
          'Tap to use your microphone.',
          'Enable microphone',
          Icons.mic_none,
        ),
        MicrophoneState.requestingPermission => (
          'Allow the microphone to record your answer.',
          'Requesting permission…',
          Icons.mic_none,
        ),
        MicrophoneState.ready => (
          'Speak after you tap Start recording.',
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
          'Recording ready. Save it, or record again.',
          'Record again',
          Icons.replay,
        ),
        MicrophoneState.failure => (
          "We couldn't save that recording. Try again.",
          'Try microphone again',
          Icons.refresh,
        ),
        MicrophoneState.permissionDenied => (
          'Microphone access is off. Allow it in phone settings, then try again.',
          'Check permission again',
          Icons.mic_off_outlined,
        ),
      };
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_home());
        },
        child: SpeakCraftPage(
          title: 'Starting assessment',
          onBack: _assessment.saving ? null : _home,
          children: [
            Text(
              'Part ${item.part} of 5 • Recording ${_assessment.index + 1} of ${_assessment.items.length}',
            ),
            LinearProgressIndicator(
              value: _assessment.index / _assessment.items.length,
              semanticsLabel:
                  'Recording ${_assessment.index + 1} of ${_assessment.items.length}',
            ),
            const SpeakCraftNotice(
              'Your recordings stay on this phone for this app session. No score is given. They are removed next time you open the app.',
            ),
            Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
            if (item.part == 2) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/assessment/salon-scene-provisional.png',
                  fit: BoxFit.cover,
                  semanticLabel: 'A stylist braids a customer’s hair in a salon. A mirror, hair tools, extensions and a dryer are visible.',
                ),
              ),
              const Text('Generated picture • educator review pending'),
            ],
            Text(
              item.instruction,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (item.part >= 4)
              SpeakCraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('CUSTOMER SAYS'),
                    const SizedBox(height: 8),
                    Text(item.spokenPrompt),
                  ],
                ),
              ),
            SpeakCraftAudioButton(
              key: ValueKey(item.id),
              text: item.spokenPrompt,
              label: item.part >= 4 ? 'Listen to customer' : 'Hear the task',
              enabled: !_mic.capturing,
              allowSlowReplay: true,
            ),
            SpeakCraftNotice(
              ownsTake || _mic.promptId == null
                  ? status
                  : 'Ready for this answer.',
              icon: icon,
              live: true,
            ),
            if (_cleanupError != null)
              SpeakCraftNotice(
                _cleanupError!,
                icon: Icons.error_outline,
                live: true,
              ),
            if (_assessment.error != null)
              SpeakCraftNotice(
                _assessment.error!,
                icon: Icons.error_outline,
                live: true,
              ),
            SpeakCraftButton(
              label: action,
              icon: icon,
              onPressed: _mic.busy || _assessment.saving
                  ? null
                  : () async {
                      switch (_mic.state) {
                        case MicrophoneState.idle:
                        case MicrophoneState.failure:
                        case MicrophoneState.permissionDenied:
                        case MicrophoneState.success:
                          await _mic.prepare();
                        case MicrophoneState.ready:
                          await _mic.start(item.id);
                        case MicrophoneState.recording:
                          await _mic.finish();
                        case MicrophoneState.requestingPermission:
                        case MicrophoneState.processing:
                          break;
                      }
                    },
            ),
            if (ownsTake && _mic.state == MicrophoneState.success)
              SpeakCraftButton(
                label: _assessment.saving
                    ? 'Saving…'
                    : 'Save answer and continue',
                icon: Icons.arrow_forward,
                onPressed: _assessment.saving ? null : _saveAndContinue,
              ),
          ],
        ),
      );
    },
  );
}
