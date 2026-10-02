import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class AssessmentCaptureStore {
  Future<String> save(String itemId, String recordingPath);
  Future<void> clear();
}

/// Temporary, private recordings for the current app session only.
class NativeAssessmentCaptureStore implements AssessmentCaptureStore {
  NativeAssessmentCaptureStore(this.directory);
  final Directory directory;

  static Future<NativeAssessmentCaptureStore> create({Directory? root}) async {
    final directory = Directory(
      '${(root ?? await getTemporaryDirectory()).path}/speakcraft-baseline-captures',
    );
    // Every launch discards the prior session's sensitive audio.
    if (await directory.exists()) await directory.delete(recursive: true);
    await directory.create(recursive: true);
    return NativeAssessmentCaptureStore(directory);
  }

  @override
  Future<String> save(String itemId, String recordingPath) async {
    if (!RegExp(r'^baseline-[a-z0-9-]{1,40}$').hasMatch(itemId)) {
      throw ArgumentError.value(itemId, 'itemId', 'Invalid baseline item');
    }
    final source = File(recordingPath);
    if (!await source.exists() || await source.length() == 0) {
      throw StateError('Recording unavailable');
    }
    final pending = File('${directory.path}/$itemId.pending');
    final target = File('${directory.path}/$itemId.m4a');
    try {
      if (await pending.exists()) await pending.delete();
      await source.copy(pending.path);
      if (await pending.length() == 0) {
        throw StateError('Empty recording copy');
      }
      // The source remains intact until the replacement has been copied.
      return (await pending.rename(target.path)).path;
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  @override
  Future<void> clear() async {
    if (await directory.exists()) await directory.delete(recursive: true);
    await directory.create(recursive: true);
  }
}
