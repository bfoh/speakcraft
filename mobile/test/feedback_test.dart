import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speakcraft/core/speech/feedback.dart';
import 'package:speakcraft/features/lesson/feedback_controller.dart';

import 'support/fakes.dart';

void main() {
  test('HTTP adapter sends bounded prompt identity and transcript', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/speech/evaluate');
      expect(request.headers['authorization'], 'Bearer pilot');
      expect(jsonDecode(request.body), {
        'lesson_id': 'day-1',
        'prompt_id': 'introduce-name',
        'transcript': 'My name is Ama.',
      });
      return http.Response(
        '{"outcome":"improve","feedback":"Try a full sentence.","example":"My name is Ama."}',
        200,
      );
    });
    final provider = HttpSpeakingFeedback(
      'https://api.example.org',
      client: client,
    );
    final result = await provider.evaluate(
      'day-1',
      'introduce-name',
      'My name is Ama.',
      'pilot',
    );
    expect(result.outcome, FeedbackOutcome.improve);
    expect(result.example, 'My name is Ama.');
    client.close();
  });

  test(
    'HTTP adapter rejects insecure remote service and bad feedback',
    () async {
      expect(HttpSpeakingFeedback('http://example.org').configured, isFalse);
      final client = MockClient(
        (request) async => http.Response(
          '{"outcome":"improve","feedback":"Try again.","example":null}',
          200,
        ),
      );
      await expectLater(
        HttpSpeakingFeedback(
          'https://api.example.org',
          client: client,
        ).evaluate('day-1', 'introduce-name', 'Hi.', 'pilot'),
        throwsA(isA<FeedbackException>()),
      );
      client.close();
    },
  );

  test('offline and unauthorized responses show safe states', () async {
    for (final (client, problem) in [
      (
        MockClient((request) async => throw const SocketException('offline')),
        FeedbackProblem.offline,
      ),
      (
        MockClient((request) async => http.Response('private error', 401)),
        FeedbackProblem.accessDenied,
      ),
    ]) {
      await expectLater(
        HttpSpeakingFeedback(
          'https://api.example.org',
          client: client,
        ).evaluate('day-1', 'introduce-name', 'Hi.', 'pilot'),
        throwsA(
          isA<FeedbackException>().having((e) => e.problem, 'problem', problem),
        ),
      );
      client.close();
    }
  });

  test('controller drops stale feedback after clear', () async {
    final provider = FakeFeedback()..gate = Completer<TeachingFeedback>();
    final controller = FeedbackController(provider);
    final pending = controller.evaluate(
      'day-1',
      'introduce-name',
      'Hi.',
      'pilot',
    );
    expect(controller.state, TeachingFeedbackState.sending);
    controller.clear();
    provider.gate!.complete(provider.result);
    await pending;
    expect(controller.state, TeachingFeedbackState.idle);
    expect(controller.result, isNull);
    controller.dispose();
  });
}
