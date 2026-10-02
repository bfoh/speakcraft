import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

abstract interface class RecordingPlayback {
  Stream<void> get completed;
  Future<void> play(String path);
  Future<void> stop();
  Future<void> dispose();
}

/// Plays one app-private recording at a time without retaining a source after stop.
class DeviceRecordingPlayback implements RecordingPlayback {
  final StreamController<void> _completed = StreamController<void>.broadcast();
  AudioPlayer? _player;
  StreamSubscription<void>? _completionSubscription;
  bool _disposed = false;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> play(String path) async {
    if (_disposed) throw StateError('Playback closed');
    final file = File(path);
    if (!path.startsWith('/') ||
        !path.endsWith('.m4a') ||
        !await file.exists() ||
        await file.length() == 0) {
      throw StateError('Recording unavailable');
    }
    await stop();
    final player = AudioPlayer();
    _player = player;
    _completionSubscription = player.onPlayerComplete.listen((_) {
      if (identical(_player, player) && !_completed.isClosed) {
        _completed.add(null);
      }
    });
    try {
      await player.play(DeviceFileSource(path));
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    final player = _player;
    _player = null;
    await _completionSubscription?.cancel();
    _completionSubscription = null;
    if (player == null) return;
    try {
      await player.stop();
    } finally {
      await player.dispose();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await stop();
    } finally {
      await _completed.close();
    }
  }
}
