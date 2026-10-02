import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakcraft/core/audio/assessment_capture_store.dart';
import 'package:speakcraft/core/curriculum/curriculum.dart';
import 'package:speakcraft/features/assessment/assessment_controller.dart';

import 'support/fakes.dart';

void main() {
  final items = Curriculum.parse(
    File('assets/curriculum/alpha.json').readAsStringSync(),
  ).baselineItems;

  test('capture advances only after a successful private save', () async {
    final store = FakeAssessmentCaptureStore()..failSave = true;
    final controller = AssessmentController(store, items);
    addTearDown(controller.dispose);
    expect(await controller.saveCurrent('/test/attempt.m4a'), isFalse);
    expect(controller.index, 0);
    expect(controller.error, contains('recording is still here'));
    store.failSave = false;
    expect(await controller.saveCurrent('/test/attempt.m4a'), isTrue);
    expect(controller.index, 1);
    expect(store.captures.keys, contains('baseline-introduction'));
    for (var i = 1; i < items.length; i++) {
      expect(await controller.saveCurrent('/test/attempt.m4a'), isTrue);
    }
    expect(controller.complete, isTrue);
    expect(controller.capturedCount, 7);
    expect(await controller.saveCurrent('/test/attempt.m4a'), isFalse);
    expect(await controller.clear(), isTrue);
    expect(controller.index, 0);
    expect(store.captures, isEmpty);
  });

  test('clear failure keeps capture state for retry', () async {
    final store = FakeAssessmentCaptureStore();
    final controller = AssessmentController(store, items);
    addTearDown(controller.dispose);
    await controller.saveCurrent('/test/attempt.m4a');
    store.failClear = true;
    expect(await controller.clear(), isFalse);
    expect(controller.index, 1);
    expect(store.captures, isNotEmpty);
    store.failClear = false;
    expect(await controller.clear(), isTrue);
    expect(store.captures, isEmpty);
  });

  test('privacy clear waits for an unfinished capture write', () async {
    final store = FakeAssessmentCaptureStore()..saveGate = Completer<void>();
    final controller = AssessmentController(store, items);
    addTearDown(controller.dispose);
    final capture = controller.saveCurrent('/test/attempt.m4a');
    var cleared = false;
    final clear = controller.clear().then((result) => cleared = result);
    await Future<void>.delayed(Duration.zero);
    expect(cleared, isFalse);
    store.saveGate!.complete();
    expect(await capture, isTrue);
    await clear;
    expect(cleared, isTrue);
    expect(store.captures, isEmpty);
    expect(controller.index, 0);
  });

  test(
    'native cache copies audio, rejects unsafe IDs and clears files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'speakcraft-baseline-test-',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final source = File('${directory.path}/source.m4a');
      await source.writeAsBytes([0, 1, 2, 3]);
      final cache = await NativeAssessmentCaptureStore.create(root: directory);
      final saved = await cache.save('baseline-introduction', source.path);
      expect(await File(saved).readAsBytes(), [0, 1, 2, 3]);
      expect(await source.exists(), isTrue);
      await expectLater(
        cache.save('../outside', source.path),
        throwsArgumentError,
      );
      await cache.clear();
      expect(await File(saved).exists(), isFalse);
      expect(await source.exists(), isTrue);
      final again = await cache.save('baseline-introduction', source.path);
      expect(await File(again).exists(), isTrue);
      await NativeAssessmentCaptureStore.create(root: directory);
      expect(await File(again).exists(), isFalse);
    },
  );
}
