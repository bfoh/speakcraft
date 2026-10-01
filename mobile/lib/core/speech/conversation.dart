import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_endpoint.dart';

enum ConversationProblem { offline, accessDenied, unavailable, failure }

class ConversationException implements Exception {
  const ConversationException(this.problem);
  final ConversationProblem problem;
}

enum ConversationSpeaker { kora, learner }

class ConversationTurn {
  const ConversationTurn(this.speaker, this.text);
  final ConversationSpeaker speaker;
  final String text;

  Map<String, String> toJson() => {'speaker': speaker.name, 'text': text};
}

class KoraReply {
  const KoraReply(this.reply, this.nextQuestion);
  final String reply;
  final String? nextQuestion;

  String get spokenText =>
      nextQuestion == null ? reply : '$reply $nextQuestion';

  factory KoraReply.fromJson(Map<String, dynamic> data) {
    final reply = data['reply'];
    final next = data['next_question'];
    if (reply is! String ||
        reply.trim().isEmpty ||
        reply.length > 180 ||
        (next != null &&
            (next is! String || next.trim().isEmpty || next.length > 180))) {
      throw const FormatException('Invalid Kora reply');
    }
    return KoraReply(reply.trim(), next is String ? next.trim() : null);
  }
}

abstract interface class KoraConversation {
  bool get configured;
  Future<KoraReply> respond(
    String lessonId,
    List<ConversationTurn> turns,
    String transcript,
    String accessToken,
  );
}

class UnconfiguredKoraConversation implements KoraConversation {
  const UnconfiguredKoraConversation();
  @override
  bool get configured => false;
  @override
  Future<KoraReply> respond(
    String lessonId,
    List<ConversationTurn> turns,
    String transcript,
    String accessToken,
  ) async => throw const ConversationException(ConversationProblem.unavailable);
}

class HttpKoraConversation implements KoraConversation {
  HttpKoraConversation(String baseUrl, {this._client}) : _baseUrl = baseUrl;

  final String _baseUrl;
  final http.Client? _client;
  Uri? get _endpoint => speechApiEndpoint(_baseUrl, '/v1/kora/respond');

  @override
  bool get configured => _endpoint != null;

  @override
  Future<KoraReply> respond(
    String lessonId,
    List<ConversationTurn> turns,
    String transcript,
    String accessToken,
  ) async {
    final endpoint = _endpoint;
    if (endpoint == null || accessToken.trim().isEmpty) {
      throw const ConversationException(ConversationProblem.unavailable);
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
              'turns': turns.map((turn) => turn.toJson()).toList(),
              'transcript': transcript,
            }),
          )
          .timeout(const Duration(seconds: 35));
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic>) throw const FormatException();
          return KoraReply.fromJson(data);
        case 401:
          throw const ConversationException(ConversationProblem.accessDenied);
        case 502:
        case 503:
        case 504:
          throw const ConversationException(ConversationProblem.unavailable);
        default:
          throw const ConversationException(ConversationProblem.failure);
      }
    } on ConversationException {
      rethrow;
    } on SocketException catch (_) {
      throw const ConversationException(ConversationProblem.offline);
    } on http.ClientException catch (_) {
      throw const ConversationException(ConversationProblem.offline);
    } on TimeoutException catch (_) {
      throw const ConversationException(ConversationProblem.offline);
    } on FormatException catch (_) {
      throw const ConversationException(ConversationProblem.failure);
    } finally {
      if (_client == null) client.close();
    }
  }
}
