import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speakcraft/core/speech/recognition.dart';
import 'package:speakcraft/features/lesson/transcription_controller.dart';

import 'support/fakes.dart';

void main() {
  late Directory directory;
  late File recording;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('speakcraft-speech-');
    recording = File('${directory.path}/attempt.m4a');
    await recording.writeAsBytes([
      0,
      0,
      0,
      24,
      ...'ftypM4A '.codeUnits,
      ...List.filled(32, 0),
    ]);
  });
  tearDown(() async => directory.delete(recursive: true));

  test('HTTP adapter uploads only after call and returns transcript', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.url.path, '/v1/speech/transcribe');
      expect(request.headers['authorization'], 'Bearer pilot');
      expect(request.bodyBytes, containsAll('ftypM4A '.codeUnits));
      return http.Response('{"transcript":"  My name is Ama.  "}', 200);
    });
    final recognition = HttpSpeechRecognition(
      'https://api.example.org',
      client: client,
    );
    expect(recognition.configured, isTrue);
    expect(calls, 0);
    expect(
      await recognition.transcribe(recording.path, 'pilot'),
      'My name is Ama.',
    );
    expect(calls, 1);
    client.close();
  });

  test('HTTP adapter rejects insecure remote URL and bad local file', () async {
    expect(HttpSpeechRecognition('http://example.org').configured, isFalse);
    final recognition = HttpSpeechRecognition('https://api.example.org');
    await expectLater(
      recognition.transcribe('${directory.path}/missing.m4a', 'pilot'),
      throwsA(
        isA<SpeechRecognitionException>().having(
          (e) => e.problem,
          'problem',
          SpeechProblem.invalidRecording,
        ),
      ),
    );
  });

  test(
    'HTTP adapter maps access and server failures without losing audio',
    () async {
      for (final (code, problem) in [
        (401, SpeechProblem.accessDenied),
        (503, SpeechProblem.unavailable),
      ]) {
        final client = MockClient(
          (request) async => http.Response('private detail', code),
        );
        final recognition = HttpSpeechRecognition(
          'https://api.example.org',
          client: client,
        );
        await expectLater(
          recognition.transcribe(recording.path, 'pilot'),
          throwsA(
            isA<SpeechRecognitionException>().having(
              (e) => e.problem,
              'problem',
              problem,
            ),
          ),
        );
        expect(await recording.exists(), isTrue);
        client.close();
      }
    },
  );

  test('offline failure keeps take and retry remains explicit', () async {
    final client = MockClient(
      (request) async => throw const SocketException('offline'),
    );
    final recognition = HttpSpeechRecognition(
      'https://api.example.org',
      client: client,
    );
    await expectLater(
      recognition.transcribe(recording.path, 'pilot'),
      throwsA(
        isA<SpeechRecognitionException>().having(
          (e) => e.problem,
          'problem',
          SpeechProblem.offline,
        ),
      ),
    );
    expect(await recording.exists(), isTrue);
    client.close();
  });

  test(
    'controller ignores a stale transcript after recording is cleared',
    () async {
      final recognition = FakeRecognition()..gate = Completer<String>();
      final controller = TranscriptionController(recognition)
        ..setAccessToken('pilot');
      final pending = controller.transcribe(recording.path);
      expect(controller.state, TranscriptionState.sending);
      controller.clear();
      recognition.gate!.complete('Old words');
      await pending;
      expect(controller.state, TranscriptionState.idle);
      expect(controller.transcript, isNull);
      controller.dispose();
    },
  );

  test('controller clears a rejected access code', () async {
    final recognition = FakeRecognition()
      ..error = const SpeechRecognitionException(SpeechProblem.accessDenied);
    final controller = TranscriptionController(recognition)
      ..setAccessToken('wrong');
    await controller.transcribe(recording.path);
    expect(controller.state, TranscriptionState.accessDenied);
    expect(controller.hasAccessToken, isFalse);
    controller.dispose();
  });
}
