import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:speakcraft/core/speech/expression.dart';
import 'package:speakcraft/features/help_me_say_it/expression_controller.dart';

const sample = UsefulExpression(
  'I think you want to suggest braids.',
  'I recommend braids because they are easy to maintain.',
  'Why do you recommend braids?',
);

class FakeGenerator implements ExpressionGenerator {
  FakeGenerator(this.result);
  final UsefulExpression? result;
  @override
  bool get configured => true;
  @override
  Future<UsefulExpression> generate(String intention, String token) async =>
      result ?? (throw const ExpressionException(ExpressionProblem.offline));
}

void main() {
  test('HTTP adapter sends reviewed intention and validates fields', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/help-me-say-it');
      expect(request.headers['authorization'], 'Bearer pilot');
      expect(jsonDecode(request.body), {
        'context_id': 'beauty-cosmetology',
        'intention': 'I want to recommend braids',
      });
      return http.Response(
        jsonEncode({
          'understood_meaning': sample.understoodMeaning,
          'expression': sample.expression,
          'customer_cue': sample.customerCue,
        }),
        200,
      );
    });
    final provider = HttpExpressionGenerator(
      'https://api.example.org',
      client: client,
    );
    expect(
      (await provider.generate(
        'I want to recommend braids',
        'pilot',
      )).expression,
      sample.expression,
    );
    client.close();
  });

  test('HTTP adapter rejects invalid endpoint, fields and offline', () async {
    expect(HttpExpressionGenerator('http://example.org').configured, isFalse);
    final bad = MockClient(
      (_) async => http.Response(
        '{"understood_meaning":"Okay","expression":" ","customer_cue":"Hello"}',
        200,
      ),
    );
    await expectLater(
      HttpExpressionGenerator(
        'https://api.example.org',
        client: bad,
      ).generate('Hello', 'pilot'),
      throwsA(isA<ExpressionException>()),
    );
    bad.close();
    final offline = MockClient(
      (_) async => throw const SocketException('offline'),
    );
    await expectLater(
      HttpExpressionGenerator(
        'https://api.example.org',
        client: offline,
      ).generate('Hello', 'pilot'),
      throwsA(
        isA<ExpressionException>().having(
          (e) => e.problem,
          'problem',
          ExpressionProblem.offline,
        ),
      ),
    );
    offline.close();
  });

  test('controller preserves intention on offline and completes only after two takes', () async {
    final failed = ExpressionController(FakeGenerator(null));
    await failed.generate('I want braids', 'pilot');
    expect(failed.stage, ExpressionStage.intention);
    expect(failed.state, ExpressionState.offline);
    failed.dispose();

    final controller = ExpressionController(FakeGenerator(sample));
    await controller.generate('I want braids', 'pilot');
    expect(controller.stage, ExpressionStage.repeat);
    expect(controller.intention, 'I want braids');
    controller.acceptTranscript('I recommend braids');
    expect(controller.stage, ExpressionStage.rolePlay);
    controller.acceptTranscript('Because they are easy to maintain');
    expect(controller.stage, ExpressionStage.done);
    expect(controller.rolePlayReply, 'Because they are easy to maintain');
    controller.reset();
    expect(controller.result, isNull);
    expect(controller.stage, ExpressionStage.intention);
    controller.dispose();
  });
}
