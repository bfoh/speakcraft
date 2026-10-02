import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../core/storage/progress_store.dart';
import '../../features/lesson/microphone_controller.dart';
import '../../features/progress/confidence_check_in.dart';
import '../../shared/components.dart';
import 'assessment_controller.dart';
import 'assessment_playback_controller.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key, this.day5Challenge = false});

  final bool day5Challenge;

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen>
    with WidgetsBindingObserver {
  late final MicrophoneController _mic;
  late final AssessmentController _assessment;
  late final AssessmentPlaybackController _playback;
  late final SessionController _session;
  String? _cleanupError;

  @override
  void initState() {
    super.initState();
    _mic = ref.read(
      widget.day5Challenge
          ? day5ChallengeMicrophoneProvider
          : assessmentMicrophoneProvider,
    );
    _assessment = ref.read(
      widget.day5Challenge ? day5ChallengeProvider : assessmentProvider,
    );
    _playback = ref.read(
      widget.day5Challenge
          ? day5ChallengePlaybackProvider
          : assessmentPlaybackProvider,
    );
    _session = ref.read(sessionProvider);
    _mic.resume();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mic.resume();
    } else {
      unawaited(_playback.stop());
      unawaited(_mic.interrupt());
    }
  }

  Future<void> _home() async {
    if (_assessment.saving) return;
    if (!await _playback.stop()) return;
    await _mic.interrupt();
    if (mounted) context.go('/home');
  }

  Future<void> _saveConfidence(int rating) async {
    await _session.update(
      _session.progress.withConfidenceCheckIn('starting', rating),
    );
  }

  Future<void> _saveAndContinue() async {
    final item = _assessment.current;
    final path = _mic.recordingPath;
    if (item == null || path == null || _mic.promptId != item.id) return;
    if (!await _playback.stop()) return;
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
        title: Text(
          widget.day5Challenge
              ? 'Clear Day 5 recordings?'
              : 'Clear starting recordings?',
        ),
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
    if (!await _playback.stop()) return;
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
    unawaited(_playback.stop());
    unawaited(_mic.interrupt());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_assessment, _mic, _playback, _session]),
    builder: (context, _) {
      final item = _assessment.current;
      if (item == null) {
        return SpeakCraftPage(
          title: widget.day5Challenge
              ? 'Day 5 salon challenge'
              : 'Starting assessment',
          onBack: _home,
          children: [
            const Icon(Icons.check_circle_outline, size: 64),
            Text(
              '${_assessment.capturedCount} recordings captured',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SpeakCraftNotice(
              widget.day5Challenge
                  ? 'You finished the fixed customer prompts. No score or progress result is available yet. These recordings stay on this phone only for this app session and are removed next time you open the app.'
                  : 'No score or assessment result is available yet. These recordings stay on this phone only for this app session and are removed next time you open the app.',
            ),
            const Text('Listen to your answers from this app session.'),
            SpeakCraftAudioButton(
              text: 'Tap an answer to hear your recording. These answers are removed next time you open the app.',
              label: 'Hear how to review',
              enabled: !_playback.busy && !_playback.playing,
            ),
            for (final savedItem in _assessment.items)
              if (_assessment.pathFor(savedItem.id) case final savedPath?)
                SpeakCraftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(savedItem.title),
                      const SizedBox(height: 8),
                      SpeakCraftButton(
                        label:
                            _playback.playing &&
                                _playback.itemId == savedItem.id
                            ? 'Stop my answer: ${savedItem.title}'
                            : 'Play my answer: ${savedItem.title}',
                        icon:
                            _playback.playing &&
                                _playback.itemId == savedItem.id
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                        onPressed: _playback.busy
                            ? null
                            : () => _playback.toggle(savedItem.id, savedPath),
                      ),
                    ],
                  ),
                ),
            if (_playback.busy)
              const SpeakCraftNotice('Opening your answer…', live: true),
            if (_playback.error != null)
              SpeakCraftNotice(
                _playback.error!,
                icon: Icons.error_outline,
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
            if (!widget.day5Challenge)
              ConfidenceCheckInCard(
                current: _session.progress.confidenceFor('starting'),
                saving: _session.saving,
                error: _session.error,
                enabled: !_playback.busy && !_playback.playing,
                onSelected: _saveConfidence,
              ),
            SpeakCraftButton(
              label: 'Go to Home',
              icon: Icons.home_outlined,
              onPressed: _home,
            ),
            OutlinedButton.icon(
              onPressed: _assessment.saving || _playback.busy ? null : _clear,
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
          title: widget.day5Challenge
              ? 'Day 5 salon challenge'
              : 'Starting assessment',
          onBack: _assessment.saving ? null : _home,
          children: [
            Text(
              widget.day5Challenge
                  ? 'Step ${item.part} of 5 • Recording ${_assessment.index + 1} of ${_assessment.items.length}'
                  : 'Part ${item.part} of 5 • Recording ${_assessment.index + 1} of ${_assessment.items.length}',
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
            if (!widget.day5Challenge && item.part == 2) ...[
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
            if (widget.day5Challenge || item.part >= 4)
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
              label: widget.day5Challenge || item.part >= 4
                  ? 'Listen to customer'
                  : 'Hear the task',
              enabled: !_mic.capturing && !_playback.busy && !_playback.playing,
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
            if (_playback.error != null)
              SpeakCraftNotice(
                _playback.error!,
                icon: Icons.error_outline,
                live: true,
              ),
            if (_playback.busy)
              const SpeakCraftNotice('Opening your answer…', live: true),
            SpeakCraftButton(
              label: action,
              icon: icon,
              onPressed: _mic.busy || _assessment.saving || _playback.busy
                  ? null
                  : () async {
                      if (_mic.state != MicrophoneState.recording &&
                          !await _playback.stop()) {
                        return;
                      }
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
            if (ownsTake &&
                _mic.state == MicrophoneState.success &&
                _mic.recordingPath != null)
              SpeakCraftButton(
                label: _playback.playing && _playback.itemId == item.id
                    ? 'Stop my answer'
                    : 'Listen to my answer',
                icon: _playback.playing && _playback.itemId == item.id
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outline,
                onPressed: _playback.busy || _assessment.saving
                    ? null
                    : () => _playback.toggle(item.id, _mic.recordingPath!),
              ),
            if (ownsTake && _mic.state == MicrophoneState.success)
              SpeakCraftButton(
                label: _assessment.saving
                    ? 'Saving…'
                    : 'Save answer and continue',
                icon: Icons.arrow_forward,
                onPressed: _assessment.saving || _playback.busy
                    ? null
                    : _saveAndContinue,
              ),
          ],
        ),
      );
    },
  );
}
