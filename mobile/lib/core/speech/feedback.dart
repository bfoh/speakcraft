import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_endpoint.dart';

enum FeedbackProblem { offline, accessDenied, unavailable, failure }

class FeedbackException implements Exception {
  const FeedbackException(this.problem);
  final FeedbackProblem problem;
}

enum FeedbackOutcome { clear, improve, retry }

class TeachingFeedback {
  const TeachingFeedback({
    required this.outcome,
    required this.feedback,
    this.example,
  });
  final FeedbackOutcome outcome;
  final String feedback;
  final String? example;

  factory TeachingFeedback.fromJson(Map<String, dynamic> data) {
    final outcome = FeedbackOutcome.values.where(
      (value) => value.name == data['outcome'],
    );
    final feedback = data['feedback'];
    final example = data['example'];
    if (outcome.length != 1 ||
        feedback is! String ||
        feedback.trim().isEmpty ||
        feedback.length > 240 ||
        (example != null && (example is! String || example.length > 180)) ||
        (outcome.single == FeedbackOutcome.improve &&
            (example is! String || example.trim().isEmpty))) {
      throw const FormatException('Invalid feedback');
    }
    return TeachingFeedback(
      outcome: outcome.single,
      feedback: feedback.trim(),
      example: example is String && example.trim().isNotEmpty
          ? example.trim()
          : null,
    );
  }
}

abstract interface class SpeakingFeedback {
  bool get configured;
  Future<TeachingFeedback> evaluate(
    String lessonId,
    String promptId,
    String transcript,
    String accessToken,
  );
}

class UnconfiguredSpeakingFeedback implements SpeakingFeedback {
  const UnconfiguredSpeakingFeedback();
  @override
  bool get configured => false;
  @override
  Future<TeachingFeedback> evaluate(
    String lessonId,
    String promptId,
    String transcript,
    String accessToken,
  ) async => throw const FeedbackException(FeedbackProblem.unavailable);
}

class HttpSpeakingFeedback implements SpeakingFeedback {
  HttpSpeakingFeedback(String baseUrl, {this._client}) : _baseUrl = baseUrl;

  final String _baseUrl;
  final http.Client? _client;
  Uri? get _endpoint => speechApiEndpoint(_baseUrl, '/v1/speech/evaluate');

  @override
  bool get configured => _endpoint != null;

  @override
  Future<TeachingFeedback> evaluate(
    String lessonId,
    String promptId,
    String transcript,
    String accessToken,
  ) async {
    final endpoint = _endpoint;
    if (endpoint == null || accessToken.trim().isEmpty) {
      throw const FeedbackException(FeedbackProblem.unavailable);
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
              'lesson_id': lessonId,
              'prompt_id': promptId,
              'transcript': transcript,
            }),
          )
          .timeout(const Duration(seconds: 35));
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic>) throw const FormatException();
          return TeachingFeedback.fromJson(data);
        case 401:
          throw const FeedbackException(FeedbackProblem.accessDenied);
        case 502:
        case 503:
        case 504:
          throw const FeedbackException(FeedbackProblem.unavailable);
        default:
          throw const FeedbackException(FeedbackProblem.failure);
      }
    } on FeedbackException {
      rethrow;
    } on SocketException catch (_) {
      throw const FeedbackException(FeedbackProblem.offline);
    } on http.ClientException catch (_) {
      throw const FeedbackException(FeedbackProblem.offline);
    } on TimeoutException catch (_) {
      throw const FeedbackException(FeedbackProblem.offline);
    } on FormatException catch (_) {
      throw const FeedbackException(FeedbackProblem.failure);
    } finally {
      if (_client == null) client.close();
    }
  }
}
