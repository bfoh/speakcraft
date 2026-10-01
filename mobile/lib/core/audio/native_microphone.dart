import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'microphone.dart';

class NativeMicrophone implements Microphone {
  NativeMicrophone(this.directory);
  final Directory directory;
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  static Future<NativeMicrophone> create({
    String folder = 'speakcraft-takes',
  }) async {
    final directory = Directory(
      '${(await getTemporaryDirectory()).path}/$folder',
    );
    // Only this application's routine takes; never traverse arbitrary paths.
    if (await directory.exists()) await directory.delete(recursive: true);
    await directory.create(recursive: true);
    return NativeMicrophone(directory);
  }

  @override
  Stream<void> get interruptions => _recorder
      .onStateChanged()
      .where((state) => state != RecordState.record)
      .map((_) {});

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    _path =
        '${directory.path}/attempt-${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 64000,
      ),
      path: _path!,
    );
  }

  @override
  Future<String> stop() async {
    final path = await _recorder.stop();
    if (path == null ||
        !await File(path).exists() ||
        await File(path).length() == 0) {
      throw StateError('No recording saved');
    }
    return path;
  }

  @override
  Future<void> discard() async {
    await _recorder.cancel();
    final path = _path;
    if (path != null && await File(path).exists()) await File(path).delete();
    _path = null;
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}
