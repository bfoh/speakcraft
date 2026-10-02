import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakcraft/features/lesson/microphone_controller.dart';

import 'support/fakes.dart';

void main() {
  late FakeMicrophone microphone;
  late MicrophoneController controller;
  setUp(() {
    microphone = FakeMicrophone();
    controller = MicrophoneController(microphone, FakeSpeech());
  });
  tearDown(() => controller.dispose());

  test('capture requires permission preparation and explicit start', () async {
    await controller.start('name');
    expect(microphone.starts, 0);
    await controller.prepare();
    expect(controller.state, MicrophoneState.ready);
    expect(microphone.starts, 0);
    await controller.start('name');
    expect(controller.state, MicrophoneState.recording);
    await controller.finish();
    expect(controller.state, MicrophoneState.success);
    expect(controller.recordingPath, '/test/recording.m4a');
    expect(controller.promptId, 'name');
    await controller.discard();
    expect(controller.state, MicrophoneState.idle);
    expect(controller.recordingPath, isNull);
  });

  test('denied permission is retryable and never starts capture', () async {
    microphone.permission = false;
    await controller.prepare();
    expect(controller.state, MicrophoneState.permissionDenied);
    await controller.start('name');
    expect(microphone.starts, 0);
    microphone.permission = true;
    await controller.prepare();
    expect(controller.state, MicrophoneState.ready);
  });

  test('start failure cleans partial audio and allows retry', () async {
    await controller.prepare();
    microphone.failStart = true;
    await controller.start('name');
    expect(controller.state, MicrophoneState.failure);
    expect(controller.recordingPath, isNull);
    expect(microphone.discards, 2);
    microphone.failStart = false;
    await controller.prepare();
    await controller.start('name');
    expect(controller.state, MicrophoneState.recording);
  });

  test('stop failure never claims success', () async {
    await controller.prepare();
    await controller.start('name');
    microphone.failStop = true;
    await controller.finish();
    expect(controller.state, MicrophoneState.failure);
    expect(controller.recordingPath, isNull);
    expect(controller.recordingDuration, isNull);
  });

  test(
    'capture time excludes start and stop processing and clears on delete',
    () async {
      controller.dispose();
      final clock = TestStopwatch();
      controller = MicrophoneController(microphone, FakeSpeech(), clock: clock);
      microphone.startGate = Completer<void>();
      await controller.prepare();
      final pending = controller.start('name');
      clock.value = const Duration(seconds: 20);
      expect(controller.recordingDuration, isNull);
      microphone.startGate!.complete();
      await pending;
      clock.value = const Duration(seconds: 7);
      microphone.stopGate = Completer<void>();
      final stopping = controller.finish();
      clock.value = const Duration(seconds: 18);
      microphone.stopGate!.complete();
      await stopping;
      expect(controller.recordingDuration, const Duration(seconds: 7));
      await controller.discard();
      expect(controller.recordingDuration, isNull);
    },
  );

  test('capture time is capped by the take limit', () async {
    controller.dispose();
    final clock = TestStopwatch();
    controller = MicrophoneController(
      microphone,
      FakeSpeech(),
      clock: clock,
      maxDuration: const Duration(seconds: 60),
    );
    await controller.prepare();
    await controller.start('name');
    clock.value = const Duration(seconds: 65);
    await controller.finish();
    expect(controller.recordingDuration, const Duration(seconds: 60));
  });

  test('repeated starts and stops are serialised', () async {
    microphone.startGate = Completer<void>();
    await controller.prepare();
    final first = controller.start('name');
    await controller.start('name');
    microphone.startGate!.complete();
    await first;
    expect(microphone.starts, 1);
    await Future.wait([controller.finish(), controller.finish()]);
    expect(microphone.stops, 1);
  });

  test(
    'background during start cancels capture, never resumes automatically',
    () async {
      microphone.startGate = Completer<void>();
      await controller.prepare();
      final start = controller.start('name');
      await controller.interrupt();
      microphone.startGate!.complete();
      await start;
      expect(controller.state, MicrophoneState.ready);
      await controller.start('name');
      expect(microphone.starts, 1);
      controller.resume();
      expect(microphone.starts, 1);
    },
  );

  test('leaving a recording finalises it without losing the take', () async {
    await controller.prepare();
    await controller.start('name');
    await controller.interrupt();
    expect(controller.state, MicrophoneState.success);
    expect(controller.recordingPath, isNotNull);
    controller.resume();
    expect(controller.state, MicrophoneState.success);
  });

  test('native interruption exits recording state', () async {
    await controller.prepare();
    await controller.start('name');
    microphone.events.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, MicrophoneState.success);
  });

  testWidgets('duration limit stops recording automatically', (tester) async {
    controller.dispose();
    microphone = FakeMicrophone();
    controller = MicrophoneController(
      microphone,
      FakeSpeech(),
      maxDuration: const Duration(seconds: 2),
    );
    await controller.prepare();
    await controller.start('name');
    await tester.pump(const Duration(seconds: 2));
    expect(controller.state, MicrophoneState.success);
    expect(microphone.stops, 1);
  });
}
