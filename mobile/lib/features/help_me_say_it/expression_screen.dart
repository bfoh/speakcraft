import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../features/lesson/microphone_controller.dart';
import '../../features/lesson/transcription_controller.dart';
import '../../shared/components.dart';
import '../../shared/pilot_access_dialog.dart';
import 'expression_controller.dart';

class ExpressionScreen extends ConsumerStatefulWidget {
  const ExpressionScreen({super.key});

  @override
  ConsumerState<ExpressionScreen> createState() => _ExpressionScreenState();
}

class _ExpressionScreenState extends ConsumerState<ExpressionScreen>
    with WidgetsBindingObserver {
  late MicrophoneController _mic;
  late TranscriptionController _transcription;
  late ExpressionController _expression;

  @override
  void initState() {
    super.initState();
    _mic = ref.read(conversationMicrophoneProvider);
    _transcription = ref.read(transcriptionProvider);
    _expression = ref.read(expressionProvider);
    _mic.resume();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startOver());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mic.resume();
    } else {
      unawaited(_mic.interrupt());
    }
  }

  Future<void> _clearTake() async {
    _transcription.clear();
    await _mic.interrupt();
    await _mic.discard();
    _mic.resume();
  }

  Future<void> _startOver() async {
    _expression.reset();
    await _clearTake();
  }

  Future<void> _home() async {
    await _startOver();
    if (mounted) context.go('/home');
  }

  Future<bool> _ensureAccessCode() async {
    if (_transcription.hasAccessToken) return true;
    final code = await askForPilotAccessCode(context);
    if (code == null || code.trim().isEmpty) return false;
    _transcription.setAccessToken(code);
    return true;
  }

  Future<void> _hearWords() async {
    if (!await _ensureAccessCode() || !mounted) return;
    final path = _mic.recordingPath;
    if (path != null) await _transcription.transcribe(path);
  }

  Future<void> _advance() async {
    final words = _transcription.transcript;
    if (words == null) return;
    if (_expression.stage == ExpressionStage.intention) {
      if (!await _ensureAccessCode() || !mounted) return;
      await _expression.generate(words, _transcription.accessToken);
      if (_expression.state == ExpressionState.accessDenied) {
        _transcription.clearAccessToken();
      }
      if (_expression.stage == ExpressionStage.repeat) await _clearTake();
    } else {
      _expression.acceptTranscript(words);
      await _clearTake();
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
    listenable: Listenable.merge([_mic, _transcription, _expression]),
    builder: (context, _) {
      final stage = _expression.stage;
      final result = _expression.result;
      final busy = _mic.busy || _transcription.sending || _expression.sending;
      final stageTitle = switch (stage) {
        ExpressionStage.intention => '1 • Say what you mean',
        ExpressionStage.repeat => '2 • Listen and repeat',
        ExpressionStage.rolePlay => '3 • Answer the customer',
        ExpressionStage.done => 'You practised the phrase',
      };
      final micLabel = switch (_mic.state) {
        MicrophoneState.idle => 'Enable microphone',
        MicrophoneState.requestingPermission => 'Requesting permission…',
        MicrophoneState.ready => 'Start recording',
        MicrophoneState.recording => 'Stop recording',
        MicrophoneState.processing => 'Please wait…',
        MicrophoneState.success => 'Record again',
        MicrophoneState.failure => 'Try microphone again',
        MicrophoneState.permissionDenied => 'Check permission again',
      };
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, value) {
          if (!didPop) unawaited(_home());
        },
        child: SpeakCraftPage(
          title: 'Help Me Say It',
          onBack: _home,
          children: [
            Text(stageTitle, style: Theme.of(context).textTheme.titleLarge),
            if (stage == ExpressionStage.intention)
              const SpeakCraftNotice(
                'Say something you want to tell a customer. Check the words before asking Kora.',
                icon: Icons.lightbulb_outline,
              ),
            if (result != null) ...[
              SpeakCraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('KORA THINKS YOU MEAN'),
                    const SizedBox(height: 8),
                    Text(result.understoodMeaning),
                    const SizedBox(height: 16),
                    const Text('TRY SAYING'),
                    const SizedBox(height: 8),
                    Text(
                      result.expression,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SpeakCraftAudioButton(
                      text: result.expression,
                      label: 'Listen to phrase',
                      enabled: !busy && _mic.state != MicrophoneState.recording,
                      allowSlowReplay: true,
                    ),
                  ],
                ),
              ),
              if (stage == ExpressionStage.repeat)
                const Text('Listen, then record yourself saying the phrase.'),
              if (stage == ExpressionStage.rolePlay ||
                  stage == ExpressionStage.done) ...[
                SpeakCraftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('CUSTOMER'),
                      const SizedBox(height: 8),
                      Text(
                        result.customerCue,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SpeakCraftAudioButton(
                        text: result.customerCue,
                        label: 'Listen to customer',
                        enabled:
                            !busy && _mic.state != MicrophoneState.recording,
                        allowSlowReplay: true,
                      ),
                    ],
                  ),
                ),
                if (stage == ExpressionStage.rolePlay)
                  const Text('Answer the customer in your own words.'),
              ],
            ],
            if (stage == ExpressionStage.done) ...[
              SpeakCraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('WHAT I HEARD'),
                    const SizedBox(height: 8),
                    Text(_expression.rolePlayReply ?? ''),
                  ],
                ),
              ),
              const SpeakCraftNotice(
                'You completed this practice. The words above are what speech recognition heard, not a speaking score.',
                icon: Icons.check_circle_outline,
              ),
              SpeakCraftButton(
                label: 'Start again',
                icon: Icons.replay,
                onPressed: _startOver,
              ),
            ] else ...[
              SpeakCraftNotice(
                switch (_mic.state) {
                  MicrophoneState.permissionDenied => 'Microphone access is off. Allow it in phone settings, then try again.',
                  MicrophoneState.failure =>
                    "We couldn't save that recording. Try again.",
                  MicrophoneState.recording =>
                    'Recording. Tap stop when you finish.',
                  MicrophoneState.processing => 'Please wait…',
                  MicrophoneState.success =>
                    'Your recording is saved for this session.',
                  _ => 'Tap the microphone and speak.',
                },
                icon: Icons.mic_none,
                live: true,
              ),
              SpeakCraftButton(
                label: micLabel,
                icon: _mic.state == MicrophoneState.recording
                    ? Icons.stop_circle_outlined
                    : Icons.mic_none,
                onPressed: busy
                    ? null
                    : () async {
                        switch (_mic.state) {
                          case MicrophoneState.ready:
                            _transcription.clear();
                            await _mic.start('help-me-say-it-${stage.name}');
                          case MicrophoneState.recording:
                            await _mic.finish();
                          default:
                            await _mic.prepare();
                        }
                      },
              ),
              if (_mic.recordingPath != null) ...[
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          await _mic.discard();
                          _transcription.clear();
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete recording'),
                ),
                if (_transcription.configured)
                  SpeakCraftButton(
                    label: _transcription.sending
                        ? 'Listening to your words…'
                        : 'Hear my words',
                    icon: Icons.hearing,
                    onPressed: busy ? null : _hearWords,
                  ),
              ],
              if (!_transcription.configured ||
                  !_expression.provider.configured)
                const SpeakCraftNotice(
                  'Kora needs a SpeakCraft server connection. You can still practise speaking here.',
                  icon: Icons.wifi_off_outlined,
                ),
              if (_transcription.state == TranscriptionState.success) ...[
                SpeakCraftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('WHAT I HEARD'),
                      const SizedBox(height: 8),
                      Text(
                        _transcription.transcript!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('If these words are wrong, record again.'),
                    ],
                  ),
                ),
                SpeakCraftButton(
                  label: switch (stage) {
                    ExpressionStage.intention =>
                      _expression.sending
                          ? 'Finding a phrase…'
                          : 'Ask Kora for English',
                    ExpressionStage.repeat => 'Continue to customer',
                    ExpressionStage.rolePlay => 'Finish practice',
                    ExpressionStage.done => 'Finish practice',
                  },
                  icon: Icons.arrow_forward,
                  onPressed: busy ? null : _advance,
                ),
              ],
              if (_transcription.state == TranscriptionState.noSpeech)
                const SpeakCraftNotice("I didn't hear words. Record again."),
              if (_transcription.state == TranscriptionState.offline ||
                  _expression.state == ExpressionState.offline)
                const SpeakCraftNotice(
                  'No connection. Your recording is still here. Try again when online.',
                  icon: Icons.wifi_off_outlined,
                ),
              if (_transcription.state == TranscriptionState.accessDenied ||
                  _expression.state == ExpressionState.accessDenied)
                const SpeakCraftNotice(
                  'Access code expired. Try again and enter the new code.',
                ),
              if (_expression.state == ExpressionState.invalid)
                const SpeakCraftNotice(
                  'That answer is too long. Please record a shorter one.',
                ),
              if (_transcription.state == TranscriptionState.unavailable ||
                  _expression.state == ExpressionState.unavailable)
                const SpeakCraftNotice(
                  'Kora is unavailable right now. Your recording is still here.',
                ),
              if (_transcription.state == TranscriptionState.failure ||
                  _transcription.state == TranscriptionState.invalidRecording ||
                  _expression.state == ExpressionState.failure)
                const SpeakCraftNotice('That did not work. Try again.'),
            ],
          ],
        ),
      );
    },
  );
}
