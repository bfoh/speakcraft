import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_endpoint.dart';

enum SpeechProblem {
  offline,
  accessDenied,
  unavailable,
  invalidRecording,
  failure,
}

class SpeechRecognitionException implements Exception {
  const SpeechRecognitionException(this.problem);
  final SpeechProblem problem;
}

abstract interface class SpeechRecognition {
  bool get configured;
  Future<String> transcribe(String recordingPath, String accessToken);
}

class UnconfiguredSpeechRecognition implements SpeechRecognition {
  const UnconfiguredSpeechRecognition();
  @override
  bool get configured => false;
  @override
  Future<String> transcribe(String recordingPath, String accessToken) async =>
      throw const SpeechRecognitionException(SpeechProblem.unavailable);
}

class HttpSpeechRecognition implements SpeechRecognition {
  HttpSpeechRecognition(String baseUrl, {this._client})
    : _baseUrl = baseUrl.trim();

  final String _baseUrl;
  final http.Client? _client;
  static const maxAudioBytes = 4 * 1024 * 1024;

  Uri? get _endpoint => speechApiEndpoint(_baseUrl, '/v1/speech/transcribe');

  @override
  bool get configured => _endpoint != null;

  @override
  Future<String> transcribe(String recordingPath, String accessToken) async {
    final endpoint = _endpoint;
    if (endpoint == null || accessToken.trim().isEmpty) {
      throw const SpeechRecognitionException(SpeechProblem.unavailable);
    }
    try {
      final file = File(recordingPath);
      if (!recordingPath.toLowerCase().endsWith('.m4a') ||
          !await file.exists() ||
          await file.length() == 0 ||
          await file.length() > maxAudioBytes) {
        throw const SpeechRecognitionException(SpeechProblem.invalidRecording);
      }
      final client = _client ?? http.Client();
      try {
        final request = http.MultipartRequest('POST', endpoint)
          ..headers['Authorization'] = 'Bearer ${accessToken.trim()}'
          ..files.add(
            await http.MultipartFile.fromPath('audio', recordingPath),
          );
        final streamed = await client
            .send(request)
            .timeout(const Duration(seconds: 35));
        final response = await http.Response.fromStream(streamed)
            .timeout(const Duration(seconds: 35));
        switch (response.statusCode) {
          case 200:
            final body = jsonDecode(response.body);
            if (body is Map<String, dynamic> && body['transcript'] is String) {
              return (body['transcript'] as String).trim();
            }
            throw const SpeechRecognitionException(SpeechProblem.failure);
          case 401:
            throw const SpeechRecognitionException(SpeechProblem.accessDenied);
          case 400:
          case 413:
            throw const SpeechRecognitionException(
              SpeechProblem.invalidRecording,
            );
          case 502:
          case 503:
          case 504:
            throw const SpeechRecognitionException(SpeechProblem.unavailable);
          default:
            throw const SpeechRecognitionException(SpeechProblem.failure);
        }
      } finally {
        if (_client == null) client.close();
      }
    } on SpeechRecognitionException {
      rethrow;
    } on SocketException catch (_) {
      throw const SpeechRecognitionException(SpeechProblem.offline);
    } on http.ClientException catch (_) {
      throw const SpeechRecognitionException(SpeechProblem.offline);
    } on TimeoutException catch (_) {
      throw const SpeechRecognitionException(SpeechProblem.offline);
    } on FileSystemException catch (_) {
      throw const SpeechRecognitionException(SpeechProblem.invalidRecording);
    } on FormatException catch (_) {
      throw const SpeechRecognitionException(SpeechProblem.failure);
    }
  }
}
