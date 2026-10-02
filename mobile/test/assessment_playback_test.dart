import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakcraft/core/audio/recording_playback.dart';
import 'package:speakcraft/features/assessment/assessment_playback_controller.dart';

import 'support/fakes.dart';

void main() {
  test('play, switch, completion and stop keep one answer active', () async {
    final playback = FakeRecordingPlayback();
    final speech = FakeSpeech();
    final controller = AssessmentPlaybackController(playback, speech);
    addTearDown(controller.dispose);
    await controller.toggle('first', '/test/first.m4a');
    expect(controller.state, AssessmentPlaybackState.playing);
    expect(controller.itemId, 'first');
    expect(playback.paths, ['/test/first.m4a']);
    expect(speech.stops, 1);
    await controller.toggle('second', '/test/second.m4a');
    expect(controller.itemId, 'second');
    expect(playback.playing, isTrue);
    expect(playback.paths, ['/test/first.m4a', '/test/second.m4a']);
    playback.complete();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, AssessmentPlaybackState.idle);
    expect(playback.playing, isFalse);
  });

  test('tap active answer stops it; failed playback stays retryable', () async {
    final playback = FakeRecordingPlayback();
    final controller = AssessmentPlaybackController(playback, FakeSpeech());
    addTearDown(controller.dispose);
    await controller.toggle('first', '/test/first.m4a');
    await controller.toggle('first', '/test/first.m4a');
    expect(controller.state, AssessmentPlaybackState.idle);
    playback.failPlay = true;
    await controller.toggle('first', '/test/first.m4a');
    expect(controller.state, AssessmentPlaybackState.failure);
    expect(controller.error, contains("couldn't play"));
    playback.failPlay = false;
    await controller.toggle('first', '/test/first.m4a');
    expect(controller.state, AssessmentPlaybackState.playing);
    expect(controller.error, isNull);
  });

  test('stop during loading prevents stale playback', () async {
    final playback = FakeRecordingPlayback()..playGate = Completer<void>();
    final controller = AssessmentPlaybackController(playback, FakeSpeech());
    addTearDown(controller.dispose);
    final pending = controller.toggle('first', '/test/first.m4a');
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, AssessmentPlaybackState.loading);
    final stopping = controller.stop();
    playback.playGate!.complete();
    await Future.wait([pending, stopping]);
    expect(controller.state, AssessmentPlaybackState.idle);
    expect(playback.playing, isFalse);
  });

  test(
    'failed stop stays visible and can be retried before deleting audio',
    () async {
      final playback = FakeRecordingPlayback();
      final controller = AssessmentPlaybackController(playback, FakeSpeech());
      addTearDown(controller.dispose);
      await controller.toggle('first', '/test/first.m4a');
      playback.failStop = true;
      expect(await controller.stop(), isFalse);
      expect(controller.state, AssessmentPlaybackState.failure);
      expect(playback.playing, isTrue);
      playback.failStop = false;
      expect(await controller.stop(), isTrue);
      expect(playback.playing, isFalse);
    },
  );

  test(
    'native adapter rejects missing or nonlocal files before playback',
    () async {
      final playback = DeviceRecordingPlayback();
      addTearDown(playback.dispose);
      await expectLater(
        playback.play('https://example.org/answer.m4a'),
        throwsStateError,
      );
      await expectLater(playback.play('/missing/answer.m4a'), throwsStateError);
    },
  );
}
