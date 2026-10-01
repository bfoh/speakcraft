import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speakcraft/core/speech/conversation.dart';
import 'package:speakcraft/core/speech/salon.dart';

void main() {
  final turns = [
    const ConversationTurn(
      ConversationSpeaker.kora,
      "Hello. I'd like braids. How much would they cost?",
    ),
  ];

  test(
    'salon adapter maps customer roles and parses a bounded reply',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/salon/respond');
        expect(request.headers['authorization'], 'Bearer pilot');
        expect(jsonDecode(request.body), {
          'scenario_id': 'friendly-braids-price',
          'turns': [
            {
              'speaker': 'customer',
              'text': "Hello. I'd like braids. How much would they cost?",
            },
          ],
          'transcript': 'Welcome. What kind of braids would you like?',
        });
        return http.Response(
          '{"customer_reply":"I like medium braids.","next_question":"Could you check the price?"}',
          200,
        );
      });
      final provider = HttpSalonConversation(
        'https://api.example.org',
        client: client,
      );
      final result = await provider.respond(
        'friendly-braids-price',
        turns,
        'Welcome. What kind of braids would you like?',
        'pilot',
      );
      expect(
        result.spokenText,
        'I like medium braids. Could you check the price?',
      );
      client.close();
    },
  );

  test(
    'salon adapter rejects insecure URLs and malformed customer text',
    () async {
      expect(HttpSalonConversation('http://example.org').configured, isFalse);
      final client = MockClient(
        (request) async =>
            http.Response('{"customer_reply":" ","next_question":null}', 200),
      );
      await expectLater(
        HttpSalonConversation(
          'https://api.example.org',
          client: client,
        ).respond('friendly-braids-price', turns, 'Hello.', 'pilot'),
        throwsA(isA<ConversationException>()),
      );
      client.close();
    },
  );

  test('offline and unauthorized requests have safe outcomes', () async {
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
        HttpSalonConversation(
          'https://api.example.org',
          client: client,
        ).respond('friendly-braids-price', turns, 'Hello.', 'pilot'),
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
}
