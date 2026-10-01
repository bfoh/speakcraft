import 'package:flutter/foundation.dart';

import '../../core/speech/recognition.dart';

enum TranscriptionState {
  idle,
  sending,
  success,
  noSpeech,
  offline,
  accessDenied,
  unavailable,
  invalidRecording,
  failure,
}

class TranscriptionController extends ChangeNotifier {
  TranscriptionController(this.recognition);
  final SpeechRecognition recognition;
  TranscriptionState state = TranscriptionState.idle;
  String? transcript;
  String? _accessToken;
  int _revision = 0;
  bool _disposed = false;

  bool get configured => recognition.configured;
  bool get hasAccessToken => _accessToken != null;
  bool get sending => state == TranscriptionState.sending;

  void setAccessToken(String value) {
    final trimmed = value.trim();
    _accessToken = trimmed.isEmpty ? null : trimmed;
  }

  void _set(TranscriptionState next) {
    if (_disposed) return;
    state = next;
    notifyListeners();
  }

  Future<void> transcribe(String recordingPath) async {
    if (sending) return;
    final token = _accessToken;
    if (!configured || token == null) {
      _set(TranscriptionState.unavailable);
      return;
    }
    final revision = ++_revision;
    transcript = null;
    _set(TranscriptionState.sending);
    try {
      final words = await recognition.transcribe(recordingPath, token);
      if (revision != _revision || _disposed) return;
      transcript = words;
      _set(
        words.isEmpty
            ? TranscriptionState.noSpeech
            : TranscriptionState.success,
      );
    } on SpeechRecognitionException catch (error) {
      if (revision != _revision || _disposed) return;
      if (error.problem == SpeechProblem.accessDenied) _accessToken = null;
      _set(switch (error.problem) {
        SpeechProblem.offline => TranscriptionState.offline,
        SpeechProblem.accessDenied => TranscriptionState.accessDenied,
        SpeechProblem.unavailable => TranscriptionState.unavailable,
        SpeechProblem.invalidRecording => TranscriptionState.invalidRecording,
        SpeechProblem.failure => TranscriptionState.failure,
      });
    } catch (_) {
      if (revision != _revision || _disposed) return;
      _set(TranscriptionState.failure);
    }
  }

  void clear() {
    _revision++;
    transcript = null;
    _set(TranscriptionState.idle);
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _accessToken = null;
    super.dispose();
  }
}
