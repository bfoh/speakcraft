import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speakcraft/core/speech/conversation.dart';
import 'package:speakcraft/features/conversation/conversation_controller.dart';

import 'support/fakes.dart';

void main() {
  const opening = 'Hello! Tell me about yourself.';
  final turns = [const ConversationTurn(ConversationSpeaker.kora, opening)];

  test(
    'HTTP adapter sends explicit bounded history and accepts reply',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/kora/respond');
        expect(request.headers['authorization'], 'Bearer pilot');
        expect(jsonDecode(request.body), {
          'lesson_id': 'day-1',
          'turns': [
            {'speaker': 'kora', 'text': opening},
          ],
          'transcript': 'My name is Ama.',
        });
        return http.Response(
          '{"reply":"Nice to meet you.","next_question":"What do you study?"}',
          200,
        );
      });
      final provider = HttpKoraConversation(
        'https://api.example.org',
        client: client,
      );
      final result = await provider.respond(
        'day-1',
        turns,
        'My name is Ama.',
        'pilot',
      );
      expect(result.spokenText, 'Nice to meet you. What do you study?');
      client.close();
    },
  );

  test('HTTP adapter rejects insecure remote URL and invalid reply', () async {
    expect(HttpKoraConversation('http://example.org').configured, isFalse);
    final client = MockClient(
      (request) async =>
          http.Response('{"reply":" ","next_question":null}', 200),
    );
    await expectLater(
      HttpKoraConversation(
        'https://api.example.org',
        client: client,
      ).respond('day-1', turns, 'Hello.', 'pilot'),
      throwsA(isA<ConversationException>()),
    );
    client.close();
  });

  test('overlong answer is rejected before a network request', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response('{}', 200);
    });
    await expectLater(
      HttpKoraConversation(
        'https://api.example.org',
        client: client,
      ).respond('day-1', turns, 'x' * 401, 'pilot'),
      throwsA(
        isA<ConversationException>().having(
          (e) => e.problem,
          'problem',
          ConversationProblem.invalidAnswer,
        ),
      ),
    );
    expect(calls, 0);
    client.close();
  });

  test('offline and access denial map to safe errors', () async {
    for (final (client, problem) in [
      (
        MockClient((request) async => throw const SocketException('offline')),
        ConversationProblem.offline,
      ),
      (
        MockClient((request) async => http.Response('private detail', 401)),
        ConversationProblem.accessDenied,
      ),
    ]) {
      await expectLater(
        HttpKoraConversation(
          'https://api.example.org',
          client: client,
        ).respond('day-1', turns, 'Hello.', 'pilot'),
        throwsA(
          isA<ConversationException>().having(
            (e) => e.problem,
            'problem',
            problem,
          ),
        ),
      );
      client.close();
    }
  });

  test('controller ignores stale result after reset', () async {
    final provider = FakeConversation()..gate = Completer<KoraReply>();
    final controller = ConversationController(
      provider: provider,
      lessonId: 'day-1',
      opening: opening,
      turnLimit: 3,
    );
    final pending = controller.send('My name is Ama.', 'pilot');
    expect(controller.state, ConversationState.sending);
    controller.reset();
    provider.gate!.complete(provider.result);
    await pending;
    expect(controller.state, ConversationState.idle);
    expect(controller.turns.length, 1);
    controller.dispose();
  });

  test('six-turn salon exchange ends at its authored limit', () async {
    final provider = FakeConversation();
    final controller = ConversationController(
      provider: provider,
      lessonId: 'complete-salon-conversation',
      opening: 'Hello. Can you help me?',
      turnLimit: 6,
    );
    for (var turn = 1; turn <= 6; turn++) {
      if (turn == 6) provider.result = const KoraReply('Thank you.', null);
      await controller.send('I can help you.', 'pilot');
      expect(controller.learnerTurns, turn);
      if (turn < 6) {
        expect(controller.complete, isFalse);
        controller.beginNewRecording();
      }
    }
    expect(controller.complete, isTrue);
    expect(controller.turns.length, 13);
    expect(provider.calls.last.$2.length, 11);
    controller.dispose();
  });
}
