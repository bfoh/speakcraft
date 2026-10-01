import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_endpoint.dart';
import 'conversation.dart';

/// Maps the shared voice-dialogue UI to the salon's customer-role contract.
class HttpSalonConversation implements KoraConversation {
  HttpSalonConversation(String baseUrl, {this._client}) : _baseUrl = baseUrl;

  final String _baseUrl;
  final http.Client? _client;
  Uri? get _endpoint => speechApiEndpoint(_baseUrl, '/v1/salon/respond');

  @override
  bool get configured => _endpoint != null;

  @override
  Future<KoraReply> respond(
    String scenarioId,
    List<ConversationTurn> turns,
    String transcript,
    String accessToken,
  ) async {
    final endpoint = _endpoint;
    if (endpoint == null || accessToken.trim().isEmpty) {
      throw const ConversationException(ConversationProblem.unavailable);
    }
    if (transcript.trim().isEmpty || transcript.length > 400) {
      throw const ConversationException(ConversationProblem.invalidAnswer);
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
              'scenario_id': scenarioId,
              'turns': turns
                  .map(
                    (turn) => {
                      'speaker': turn.speaker == ConversationSpeaker.kora
                          ? 'customer'
                          : 'learner',
                      'text': turn.text,
                    },
                  )
                  .toList(),
              'transcript': transcript,
            }),
          )
          .timeout(const Duration(seconds: 35));
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          if (data is! Map<String, dynamic>) throw const FormatException();
          final reply = data['customer_reply'];
          final next = data['next_question'];
          if (reply is! String ||
              reply.trim().isEmpty ||
              reply.length > 180 ||
              (next != null &&
                  (next is! String ||
                      next.trim().isEmpty ||
                      next.length > 180))) {
            throw const FormatException('Invalid customer reply');
          }
          return KoraReply(reply.trim(), next is String ? next.trim() : null);
        case 401:
          throw const ConversationException(ConversationProblem.accessDenied);
        case 400:
        case 413:
        case 422:
          throw const ConversationException(ConversationProblem.invalidAnswer);
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
