import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_endpoint.dart';

enum ExpressionProblem { offline, accessDenied, unavailable, invalid, failure }

class ExpressionException implements Exception {
  const ExpressionException(this.problem);
  final ExpressionProblem problem;
}

class UsefulExpression {
  const UsefulExpression(
    this.understoodMeaning,
    this.expression,
    this.customerCue,
  );
  final String understoodMeaning;
  final String expression;
  final String customerCue;

  factory UsefulExpression.fromJson(Map<String, dynamic> data) {
    String field(String name) {
      final value = data[name];
      if (value is! String || value.trim().isEmpty || value.length > 160) {
        throw const FormatException('Invalid expression');
      }
      return value.trim();
    }

    return UsefulExpression(
      field('understood_meaning'),
      field('expression'),
      field('customer_cue'),
    );
  }
}

abstract interface class ExpressionGenerator {
  bool get configured;
  Future<UsefulExpression> generate(String intention, String accessToken);
}

class UnconfiguredExpressionGenerator implements ExpressionGenerator {
  const UnconfiguredExpressionGenerator();
  @override
  bool get configured => false;
  @override
  Future<UsefulExpression> generate(
    String intention,
    String accessToken,
  ) async => throw const ExpressionException(ExpressionProblem.unavailable);
}

class HttpExpressionGenerator implements ExpressionGenerator {
  HttpExpressionGenerator(String baseUrl, {this._client}) : _baseUrl = baseUrl;

  final String _baseUrl;
  final http.Client? _client;
  Uri? get _endpoint => speechApiEndpoint(_baseUrl, '/v1/help-me-say-it');
  @override
  bool get configured => _endpoint != null;

  @override
  Future<UsefulExpression> generate(
    String intention,
    String accessToken,
  ) async {
    final endpoint = _endpoint;
    if (endpoint == null || accessToken.trim().isEmpty) {
      throw const ExpressionException(ExpressionProblem.unavailable);
    }
    if (intention.trim().isEmpty || intention.length > 400) {
      throw const ExpressionException(ExpressionProblem.invalid);
    }
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer ${accessToken.trim()}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'context_id': 'beauty-cosmetology',
              'intention': intention.trim(),
            }),
          )
          .timeout(const Duration(seconds: 35));
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic>) throw const FormatException();
          return UsefulExpression.fromJson(data);
        case 401:
          throw const ExpressionException(ExpressionProblem.accessDenied);
        case 400:
        case 413:
        case 422:
          throw const ExpressionException(ExpressionProblem.invalid);
        case 502:
        case 503:
        case 504:
          throw const ExpressionException(ExpressionProblem.unavailable);
        default:
          throw const ExpressionException(ExpressionProblem.failure);
      }
    } on ExpressionException {
      rethrow;
    } on SocketException catch (_) {
      throw const ExpressionException(ExpressionProblem.offline);
    } on http.ClientException catch (_) {
      throw const ExpressionException(ExpressionProblem.offline);
    } on TimeoutException catch (_) {
      throw const ExpressionException(ExpressionProblem.offline);
    } on FormatException catch (_) {
      throw const ExpressionException(ExpressionProblem.failure);
    } finally {
      if (_client == null) client.close();
    }
  }
}
