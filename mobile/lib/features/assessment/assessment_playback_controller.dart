import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/audio/recording_playback.dart';
import '../../core/audio/speech_output.dart';

enum AssessmentPlaybackState { idle, loading, playing, failure }

class AssessmentPlaybackController extends ChangeNotifier {
  AssessmentPlaybackController(this.playback, this.speech) {
    _completion = playback.completed.listen((_) => unawaited(stop()));
  }

  final RecordingPlayback playback;
  final SpeechOutput speech;
  late final StreamSubscription<void> _completion;
  AssessmentPlaybackState state = AssessmentPlaybackState.idle;
  String? itemId;
  String? error;
  Future<void>? _pending;
  int _revision = 0;
  bool _disposed = false;

  bool get busy => state == AssessmentPlaybackState.loading;
  bool get playing => state == AssessmentPlaybackState.playing;

  Future<void> toggle(String id, String path) async {
    if (busy) return;
    if (playing && itemId == id) {
      await stop();
      return;
    }
    final revision = ++_revision;
    _set(AssessmentPlaybackState.loading, id);
    final operation = () async {
      try {
        await playback.stop();
        await speech.stop().catchError((Object _) {});
        if (revision != _revision || _disposed) return;
        await playback.play(path);
        if (revision != _revision || _disposed) {
          await playback.stop();
          return;
        }
        _set(AssessmentPlaybackState.playing, id);
      } catch (_) {
        if (revision == _revision && !_disposed) {
          _set(AssessmentPlaybackState.failure, null);
        }
      }
    }();
    _pending = operation;
    await operation;
    if (identical(_pending, operation)) _pending = null;
  }

  Future<bool> stop() async {
    ++_revision;
    await _pending;
    try {
      await playback.stop();
      _set(AssessmentPlaybackState.idle, null);
      return true;
    } catch (_) {
      _set(AssessmentPlaybackState.failure, null);
      return false;
    }
  }

  void _set(AssessmentPlaybackState next, String? id) {
    if (_disposed) return;
    state = next;
    itemId = id;
    error = next == AssessmentPlaybackState.failure
        ? "We couldn't play that answer. Try again."
        : null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    unawaited(_completion.cancel());
    unawaited(playback.dispose());
    super.dispose();
  }
}
