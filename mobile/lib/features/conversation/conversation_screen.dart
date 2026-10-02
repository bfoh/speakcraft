import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../core/speech/conversation.dart';
import '../../features/lesson/microphone_controller.dart';
import '../../features/lesson/transcription_controller.dart';
import '../../shared/components.dart';
import '../../shared/pilot_access_dialog.dart';
import 'conversation_controller.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    this.salon = false,
    this.scenarioId = 'friendly-braids-price',
  });
  final bool salon;
  final String scenarioId;
  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen>
    with WidgetsBindingObserver {
  late MicrophoneController _mic;
  late TranscriptionController _transcription;
  late ConversationController _conversation;

  @override
  void initState() {
    super.initState();
    _mic = ref.read(conversationMicrophoneProvider);
    _transcription = ref.read(transcriptionProvider);
    _conversation = widget.salon
        ? ref.read(salonConversationProvider(widget.scenarioId))
        : ref.read(conversationProvider);
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

  Future<void> _startOver() async {
    _conversation.reset();
    _transcription.clear();
    await _mic.interrupt();
    await _mic.discard();
    _mic.resume();
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

  Future<void> _reply() async {
    if (!await _ensureAccessCode() || !mounted) return;
    final words = _transcription.transcript;
    if (words == null) return;
    await _conversation.send(words, _transcription.accessToken);
    if (_conversation.state == ConversationState.accessDenied) {
      _transcription.clearAccessToken();
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
    listenable: Listenable.merge([_mic, _transcription, _conversation]),
    builder: (context, _) {
      final scenario = ref
          .read(servicesProvider)
          .curriculum
          .scenarioForId(widget.scenarioId)!;
      final partner = widget.salon ? 'CUSTOMER' : 'KORA';
      final (status, button, icon) = switch (_mic.state) {
        MicrophoneState.idle => (
          'Tap to use your microphone.',
          'Enable microphone',
          Icons.mic_none,
        ),
        MicrophoneState.requestingPermission => (
          widget.salon
              ? 'Allow the microphone to speak with the customer.'
              : 'Allow the microphone to speak with Kora.',
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
          'Your answer is saved for this session.',
          _conversation.waitingForRecording
              ? 'Prepare next answer'
              : 'Record again',
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
      final controlsBusy =
          _mic.capturing || _transcription.sending || _conversation.sending;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_home());
        },
        child: SpeakCraftPage(
          title: widget.salon ? 'AI Salon' : 'Talk with Kora',
          onBack: _home,
          children: [
            if (widget.salon) ...[
              const Text('Practise with a simulated customer.'),
              Text(
                scenario.scenarioGoal,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SpeakCraftNotice(
                widget.scenarioId == 'friendly-braids-price'
                    ? 'No salon price is set here. Ask about the style and offer to check the price.'
                    : 'Ask questions and respond to the customer. Do not promise a real price or booking.',
                icon: Icons.info_outline,
              ),
            ] else
              const Text(
                'Practise introducing yourself in a short conversation.',
              ),
            SpeakCraftNotice(
              'Turn ${_conversation.complete ? _conversation.learnerTurns : _conversation.learnerTurns + 1} of ${_conversation.turnLimit}',
              icon: Icons.chat_bubble_outline,
            ),
            for (final turn in _conversation.turns)
              SpeakCraftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      turn.speaker == ConversationSpeaker.kora
                          ? partner
                          : 'YOU',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      turn.text,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (turn.speaker == ConversationSpeaker.kora) ...[
                      const SizedBox(height: 12),
                      SpeakCraftAudioButton(
                        text: turn.text,
                        label: widget.salon
                            ? 'Listen to customer'
                            : 'Listen to Kora',
                        enabled: !controlsBusy,
                      ),
                    ],
                  ],
                ),
              ),
            if (!_conversation.complete) ...[
              SpeakCraftNotice(status, icon: icon, live: true),
              SpeakCraftButton(
                label: button,
                icon: icon,
                onPressed:
                    _mic.busy || _transcription.sending || _conversation.sending
                    ? null
                    : () async {
                        switch (_mic.state) {
                          case MicrophoneState.ready:
                            _transcription.clear();
                            _conversation.beginNewRecording();
                            await _mic.start(
                              widget.salon
                                  ? widget.scenarioId
                                  : 'conversation-day-1',
                            );
                          case MicrophoneState.recording:
                            await _mic.finish();
                          default:
                            await _mic.prepare();
                        }
                      },
              ),
              if (_mic.recordingPath != null &&
                  !_conversation.waitingForRecording) ...[
                OutlinedButton.icon(
                  onPressed: controlsBusy
                      ? null
                      : () async {
                          await _mic.discard();
                          if (_mic.recordingPath == null) {
                            _transcription.clear();
                          }
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete answer'),
                ),
                if (_transcription.configured)
                  SpeakCraftButton(
                    label: _transcription.sending
                        ? 'Listening to your words…'
                        : 'Hear my words',
                    icon: Icons.hearing,
                    onPressed: controlsBusy ? null : _hearWords,
                  ),
              ],
              if (!_transcription.configured ||
                  !_conversation.provider.configured)
                SpeakCraftNotice(
                  widget.salon
                      ? 'AI Salon needs a SpeakCraft server connection. You can still practise speaking here.'
                      : 'Kora needs a SpeakCraft server connection. You can still practise speaking here.',
                  icon: Icons.wifi_off_outlined,
                ),
              if (_transcription.state == TranscriptionState.success &&
                  !_conversation.waitingForRecording) ...[
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
                  label: _conversation.sending
                      ? (widget.salon
                            ? 'Customer is thinking…'
                            : 'Kora is thinking…')
                      : (widget.salon
                            ? 'Send reply to customer'
                            : 'Send reply to Kora'),
                  icon: Icons.send_outlined,
                  onPressed: controlsBusy ? null : _reply,
                ),
              ],
              if (_transcription.state == TranscriptionState.noSpeech)
                const SpeakCraftNotice(
                  "I couldn't hear words. Record again.",
                  icon: Icons.hearing_disabled_outlined,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.offline ||
                  _conversation.state == ConversationState.offline)
                const SpeakCraftNotice(
                  "We couldn't connect. Your answer is still here. Try again when online.",
                  icon: Icons.wifi_off_outlined,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.accessDenied ||
                  _conversation.state == ConversationState.accessDenied)
                const SpeakCraftNotice(
                  'That access code did not work. Ask your facilitator and try again.',
                  icon: Icons.lock_outline,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.unavailable ||
                  _conversation.state == ConversationState.unavailable)
                SpeakCraftNotice(
                  widget.salon
                      ? 'AI Salon is unavailable right now. Your answer is still here.'
                      : 'Kora is unavailable right now. Your answer is still here.',
                  icon: Icons.cloud_off_outlined,
                  live: true,
                ),
              if (_conversation.state == ConversationState.invalidAnswer)
                const SpeakCraftNotice(
                  'Please try a shorter answer, about one or two sentences.',
                  icon: Icons.short_text,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.failure ||
                  _conversation.state == ConversationState.failure)
                const SpeakCraftNotice(
                  'Something went wrong. Your answer is still here. Try again.',
                  icon: Icons.error_outline,
                  live: true,
                ),
            ] else ...[
              SpeakCraftNotice(
                widget.salon
                    ? 'Salon conversation finished. Review your words above or try again. This is practice, not a score.'
                    : 'Conversation finished. You can practise again.',
                icon: Icons.check_circle_outline,
              ),
              OutlinedButton.icon(
                onPressed: _startOver,
                icon: const Icon(Icons.replay),
                label: Text(
                  widget.salon
                      ? 'Start salon again'
                      : 'Start conversation again',
                ),
              ),
            ],
            SpeakCraftNotice(
              widget.salon
                  ? 'Your voice stays on this phone until you choose Hear my words. Send reply sends the words you see to the simulated customer. This practice is not saved.'
                  : 'Your voice stays on this phone until you choose Hear my words. Send reply sends the words you see to Kora. This conversation is not saved.',
              icon: Icons.privacy_tip_outlined,
            ),
            OutlinedButton.icon(
              onPressed: _home,
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      );
    },
  );
}
