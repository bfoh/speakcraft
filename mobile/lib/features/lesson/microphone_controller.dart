import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/audio/microphone.dart';
import '../../core/audio/speech_output.dart';

enum MicrophoneState {
  idle,
  requestingPermission,
  ready,
  recording,
  processing,
  success,
  failure,
  permissionDenied,
}

class MicrophoneController extends ChangeNotifier {
  MicrophoneController(
    this.microphone,
    this.speech, {
    this.maxDuration = const Duration(seconds: 60),
  }) {
    _subscription = microphone.interruptions.listen(
      (_) {
        if (state == MicrophoneState.recording) unawaited(finish());
      },
      onError: (Object error) {
        unawaited(interrupt());
      },
    );
  }
  final Microphone microphone;
  final SpeechOutput speech;
  final Duration maxDuration;
  late final StreamSubscription<void> _subscription;
  MicrophoneState state = MicrophoneState.idle;
  String? recordingPath;
  String? promptId;
  Timer? _timer;
  bool _backgrounded = false;
  bool _disposed = false;

  bool get busy =>
      state == MicrophoneState.requestingPermission ||
      state == MicrophoneState.processing;
  bool get capturing => state == MicrophoneState.recording || busy;

  void _set(MicrophoneState next) {
    if (_disposed) return;
    state = next;
    notifyListeners();
  }

  Future<void> prepare() async {
    if (busy || state == MicrophoneState.recording) return;
    _set(MicrophoneState.requestingPermission);
    try {
      final granted = await microphone.requestPermission();
      _set(granted ? MicrophoneState.ready : MicrophoneState.permissionDenied);
    } catch (_) {
      _set(MicrophoneState.failure);
    }
  }

  Future<void> start(String id) async {
    if (state != MicrophoneState.ready || _backgrounded) return;
    _set(MicrophoneState.processing);
    try {
      await speech.stop();
      await microphone.discard();
      recordingPath = null;
      promptId = id;
      await microphone.start();
      if (_backgrounded || _disposed) {
        await microphone.discard();
        _set(MicrophoneState.ready);
        return;
      }
      _set(MicrophoneState.recording);
      _timer = Timer(maxDuration, () => unawaited(finish()));
    } catch (_) {
      // Best effort cleanup; never report a partial file as a successful take.
      try {
        await microphone.discard();
      } catch (_) {
        /* Retry performs cleanup again. */
      }
      _set(MicrophoneState.failure);
    }
  }

  Future<void> finish() async {
    if (state != MicrophoneState.recording) return;
    _timer?.cancel();
    _set(MicrophoneState.processing);
    try {
      recordingPath = await microphone.stop();
      _set(MicrophoneState.success);
    } catch (_) {
      try {
        await microphone.discard();
      } catch (_) {
        // Keep the failure visible; retry must attempt cleanup again.
      }
      recordingPath = null;
      _set(MicrophoneState.failure);
    }
  }

  Future<void> discard() async {
    if (busy || state == MicrophoneState.recording) return;
    _set(MicrophoneState.processing);
    try {
      await microphone.discard();
      recordingPath = null;
      promptId = null;
      _set(MicrophoneState.idle);
    } catch (_) {
      _set(MicrophoneState.failure);
    }
  }

  Future<void> interrupt() async {
    _backgrounded = true;
    await finish();
    await speech.stop().catchError((Object _) {});
  }

  /// Erase the current take before clearing local learner data.
  Future<bool> clearForPrivacy() async {
    _backgrounded = true;
    if (busy) return false;
    _timer?.cancel();
    if (state == MicrophoneState.recording) await finish();
    try {
      await speech.stop();
      await microphone.discard();
      recordingPath = null;
      promptId = null;
      _set(MicrophoneState.idle);
      return true;
    } catch (_) {
      _set(MicrophoneState.failure);
      return false;
    }
  }

  void resume() {
    _backgrounded = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_subscription.cancel());
    unawaited(microphone.dispose());
    super.dispose();
  }
}
