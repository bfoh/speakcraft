import 'dart:async';

import 'package:speakcraft/core/audio/microphone.dart';
import 'package:speakcraft/core/audio/speech_output.dart';
import 'package:speakcraft/core/storage/progress_store.dart';

/// Test-only adapters; production always uses native recording and SQLite.
class FakeMicrophone implements Microphone {
  bool permission = true;
  bool failStart = false;
  bool failStop = false;
  int starts = 0;
  int stops = 0;
  int discards = 0;
  Completer<void>? startGate;
  Completer<bool>? permissionGate;
  final events = StreamController<void>.broadcast();
  @override
  Stream<void> get interruptions => events.stream;
  @override
  Future<bool> requestPermission() async =>
      permissionGate == null ? permission : await permissionGate!.future;
  @override
  Future<void> start() async {
    starts++;
    if (startGate != null) await startGate!.future;
    if (failStart) throw StateError('Test recording failure');
  }

  @override
  Future<String> stop() async {
    stops++;
    if (failStop) throw StateError('Test stop failure');
    return '/test/recording.m4a';
  }

  @override
  Future<void> discard() async {
    discards++;
  }

  @override
  Future<void> dispose() async {
    await events.close();
  }
}

class FakeSpeech implements SpeechOutput {
  final spoken = <String>[];
  bool unavailable = false;
  @override
  Future<void> speak(String text) async {
    if (unavailable) throw StateError('No test voice');
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}

class MemoryProgressStore implements ProgressStore {
  LearnerProgress progress = const LearnerProgress();
  bool failSave = false;
  Completer<void>? saveGate;
  @override
  Future<LearnerProgress> load() async => progress;
  @override
  Future<void> save(LearnerProgress next) async {
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('Test disk full');
    progress = next;
  }

  @override
  Future<void> close() async {}
}
