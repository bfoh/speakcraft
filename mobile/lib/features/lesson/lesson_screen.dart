import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/services.dart';
import '../../shared/components.dart';
import 'microphone_controller.dart';
import 'transcription_controller.dart';
import 'feedback_controller.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});
  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with WidgetsBindingObserver {
  late MicrophoneController _mic;
  late TranscriptionController _transcription;
  late FeedbackController _feedback;
  @override
  void initState() {
    super.initState();
    _mic = ref.read(microphoneProvider);
    _transcription = ref.read(transcriptionProvider);
    _feedback = ref.read(feedbackProvider);
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

  Future<void> _hearMyWords(String path) async {
    _feedback.clear();
    if (!_transcription.hasAccessToken) {
      var input = '';
      final code = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connect speech recognition'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ask your facilitator for the pilot access code. It is used only while this app is open.',
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Access code'),
                onChanged: (value) => input = value,
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(input),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (code == null || code.trim().isEmpty) return;
      _transcription.setAccessToken(code);
    }
    if (mounted) await _transcription.transcribe(path);
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final session = ref.watch(sessionProvider);
    final lesson = services.curriculum.dayOne;
    return ListenableBuilder(
      listenable: Listenable.merge([_mic, session, _transcription, _feedback]),
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
            'Your recording is saved for this session.',
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
                onPressed:
                    _mic.busy ||
                        session.saving ||
                        _transcription.sending ||
                        _feedback.sending
                    ? null
                    : () async {
                        switch (_mic.state) {
                          case MicrophoneState.ready:
                            _transcription.clear();
                            _feedback.clear();
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
                  onPressed:
                      _mic.capturing ||
                          _transcription.sending ||
                          _feedback.sending
                      ? null
                      : () async {
                          await _mic.discard();
                          if (_mic.recordingPath == null) {
                            _transcription.clear();
                            _feedback.clear();
                          }
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete recording'),
                ),
              const SpeakCraftNotice(
                'Your voice stays on this phone unless you choose Hear my words. That sends the recording for speech recognition. Help me say it better sends the words you see for feedback.',
                icon: Icons.privacy_tip_outlined,
              ),
              if (_mic.recordingPath != null && _transcription.configured)
                SpeakCraftButton(
                  label: _transcription.sending
                      ? 'Listening to your words…'
                      : 'Hear my words',
                  icon: Icons.hearing,
                  onPressed:
                      _transcription.sending ||
                          _mic.capturing ||
                          _feedback.sending
                      ? null
                      : () => _hearMyWords(_mic.recordingPath!),
                ),
              if (_mic.recordingPath != null && !_transcription.configured)
                const SpeakCraftNotice(
                  'Speech recognition needs a SpeakCraft server connection. You can still practise without internet.',
                  icon: Icons.wifi_off_outlined,
                ),
              if (_transcription.state == TranscriptionState.success)
                SpeakCraftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('WHAT I HEARD'),
                      const SizedBox(height: 12),
                      Text(
                        _transcription.transcript!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SpeakCraftAudioButton(
                        text: _transcription.transcript!,
                        label: 'Listen to what I heard',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Speech recognition can make mistakes. You can try again.',
                      ),
                    ],
                  ),
                ),
              if (_transcription.state == TranscriptionState.success &&
                  _feedback.provider.configured)
                SpeakCraftButton(
                  label: _feedback.sending
                      ? 'Thinking about your words…'
                      : 'Help me say it better',
                  icon: Icons.lightbulb_outline,
                  onPressed: _feedback.sending || _mic.capturing
                      ? null
                      : () => _feedback.evaluate(
                          lesson.id,
                          prompt.id,
                          _transcription.transcript!,
                          _transcription.accessToken,
                        ),
                ),
              if (_feedback.state == TeachingFeedbackState.success)
                SpeakCraftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('KORA SAYS'),
                      const SizedBox(height: 12),
                      Text(
                        _feedback.result!.feedback,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SpeakCraftAudioButton(
                        text: _feedback.result!.feedback,
                        label: 'Listen to Kora',
                        enabled: !_mic.capturing,
                      ),
                      if (_feedback.result!.example != null) ...[
                        const SizedBox(height: 12),
                        Text(_feedback.result!.example!),
                        const SizedBox(height: 12),
                        SpeakCraftAudioButton(
                          text: _feedback.result!.example!,
                          label: 'Listen and try again',
                          enabled: !_mic.capturing,
                        ),
                      ],
                    ],
                  ),
                ),
              if (_feedback.state == TeachingFeedbackState.offline)
                const SpeakCraftNotice(
                  "We couldn't connect for feedback. Your words and recording are still here.",
                  icon: Icons.wifi_off_outlined,
                  live: true,
                ),
              if (_feedback.state == TeachingFeedbackState.accessDenied)
                const SpeakCraftNotice(
                  'The access code has stopped working. Ask your facilitator.',
                  icon: Icons.lock_outline,
                  live: true,
                ),
              if (_feedback.state == TeachingFeedbackState.unavailable)
                const SpeakCraftNotice(
                  'Feedback is unavailable right now. You can still practise.',
                  icon: Icons.cloud_off_outlined,
                  live: true,
                ),
              if (_feedback.state == TeachingFeedbackState.failure)
                const SpeakCraftNotice(
                  'Something went wrong with feedback. You can try again.',
                  icon: Icons.error_outline,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.noSpeech)
                const SpeakCraftNotice(
                  "I couldn't hear words in that recording. Try speaking again.",
                  icon: Icons.hearing_disabled_outlined,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.offline)
                const SpeakCraftNotice(
                  "We couldn't connect. Your recording is still here. Try again when you're online.",
                  icon: Icons.wifi_off_outlined,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.accessDenied)
                const SpeakCraftNotice(
                  'That access code did not work. Ask your facilitator and try again.',
                  icon: Icons.lock_outline,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.unavailable)
                const SpeakCraftNotice(
                  'Speech recognition is unavailable right now. Your recording is still here.',
                  icon: Icons.cloud_off_outlined,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.invalidRecording)
                const SpeakCraftNotice(
                  "We couldn't use that recording. Please record again.",
                  icon: Icons.mic_off_outlined,
                  live: true,
                ),
              if (_transcription.state == TranscriptionState.failure)
                const SpeakCraftNotice(
                  'Something went wrong while listening. Your recording is still here. Try again.',
                  icon: Icons.error_outline,
                  live: true,
                ),
              if (session.error != null)
                SpeakCraftNotice(
                  session.error!,
                  icon: Icons.error_outline,
                  live: true,
                ),
              if (index < lesson.prompts.length - 1)
                OutlinedButton.icon(
                  onPressed:
                      _mic.capturing ||
                          session.saving ||
                          _transcription.sending ||
                          _feedback.sending
                      ? null
                      : () async {
                          final saved = await session.update(
                            session.progress.copyWith(dayOnePrompt: index + 1),
                          );
                          if (saved) {
                            await _mic.discard();
                            if (_mic.recordingPath == null) {
                              _transcription.clear();
                              _feedback.clear();
                            }
                          }
                        },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(session.saving ? 'Saving…' : 'Next practice'),
                )
              else ...[
                const SpeakCraftNotice(
                  'Keep practising your introduction. We have not assessed or scored your speaking.',
                ),
                OutlinedButton.icon(
                  onPressed:
                      _mic.capturing ||
                          session.saving ||
                          _transcription.sending ||
                          _feedback.sending
                      ? null
                      : () async {
                          final saved = await session.update(
                            session.progress.copyWith(dayOnePrompt: 0),
                          );
                          if (saved) {
                            await _mic.discard();
                            if (_mic.recordingPath == null) {
                              _transcription.clear();
                              _feedback.clear();
                            }
                          }
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
