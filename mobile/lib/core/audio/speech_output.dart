import 'package:flutter_tts/flutter_tts.dart';

abstract interface class SpeechOutput {
  Future<void> speak(String text);
  Future<void> stop();
}

/// Reads authored instructions, never learner recordings or generated feedback.
class DeviceSpeechOutput implements SpeechOutput {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> speak(String text) async {
    await _tts.stop();
    final reported = await _tts.getLanguages;
    final languages = reported is List
        ? reported.whereType<String>().toList()
        : <String>[];
    final english = languages
        .where((language) => language.toLowerCase().startsWith('en-'))
        .toList();
    if (english.isEmpty) {
      throw StateError('English voice unavailable');
    }
    String? voice;
    for (final preferred in ['en-GH', 'en-GB', 'en-US']) {
      for (final language in english) {
        if (language.toLowerCase() == preferred.toLowerCase()) {
          voice = language;
          break;
        }
      }
      if (voice != null) break;
    }
    await _tts.setLanguage(voice ?? english.first);
    await _tts.setSpeechRate(0.4);
    await _tts.awaitSpeakCompletion(true);
    final result = await _tts.speak(text);
    if (result != 1) throw StateError('Audio unavailable');
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
