import 'dart:async';

import 'package:speakcraft/core/audio/microphone.dart';
import 'package:speakcraft/core/audio/speech_output.dart';
import 'package:speakcraft/core/storage/progress_store.dart';
import 'package:speakcraft/core/speech/recognition.dart';
import 'package:speakcraft/core/speech/feedback.dart';
import 'package:speakcraft/core/speech/conversation.dart';
import 'package:speakcraft/core/speech/expression.dart';

/// Test-only adapters; production always uses native recording and SQLite.
class FakeMicrophone implements Microphone {
  bool permission = true;
  bool failStart = false;
  bool failStop = false;
  int starts = 0;
  int stops = 0;
  int discards = 0;
  Completer<void>? startGate;
  Completer<bool>? permissionGate;
  final events = StreamController<void>.broadcast();
  @override
  Stream<void> get interruptions => events.stream;
  @override
  Future<bool> requestPermission() async =>
      permissionGate == null ? permission : await permissionGate!.future;
  @override
  Future<void> start() async {
    starts++;
    if (startGate != null) await startGate!.future;
    if (failStart) throw StateError('Test recording failure');
  }

  @override
  Future<String> stop() async {
    stops++;
    if (failStop) throw StateError('Test stop failure');
    return '/test/recording.m4a';
  }

  @override
  Future<void> discard() async {
    discards++;
  }

  @override
  Future<void> dispose() async {
    await events.close();
  }
}

class FakeSpeech implements SpeechOutput {
  final spoken = <String>[];
  bool unavailable = false;
  @override
  Future<void> speak(String text) async {
    if (unavailable) throw StateError('No test voice');
    spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}

class FakeRecognition implements SpeechRecognition {
  String result = 'My name is Ama.';
  SpeechRecognitionException? error;
  Completer<String>? gate;
  final calls = <(String, String)>[];
  @override
  bool get configured => true;
  @override
  Future<String> transcribe(String recordingPath, String accessToken) async {
    calls.add((recordingPath, accessToken));
    if (error != null) throw error!;
    return gate == null ? result : gate!.future;
  }
}

class FakeFeedback implements SpeakingFeedback {
  TeachingFeedback result = const TeachingFeedback(
    outcome: FeedbackOutcome.improve,
    feedback: 'Good start. Make your sentence clearer.',
    example: 'My name is Ama.',
  );
  FeedbackException? error;
  Completer<TeachingFeedback>? gate;
  final calls = <(String, String, String, String)>[];
  @override
  bool get configured => true;
  @override
  Future<TeachingFeedback> evaluate(
    String lessonId,
    String promptId,
    String transcript,
    String accessToken,
  ) async {
    calls.add((lessonId, promptId, transcript, accessToken));
    if (error != null) throw error!;
    return gate == null ? result : gate!.future;
  }
}

class FakeConversation implements KoraConversation {
  KoraReply result = const KoraReply(
    'Nice to meet you.',
    'Why did you choose it?',
  );
  ConversationException? error;
  Completer<KoraReply>? gate;
  final calls = <(String, List<ConversationTurn>, String, String)>[];
  @override
  bool get configured => true;
  @override
  Future<KoraReply> respond(
    String lessonId,
    List<ConversationTurn> turns,
    String transcript,
    String accessToken,
  ) async {
    calls.add((lessonId, turns, transcript, accessToken));
    if (error != null) throw error!;
    return gate == null ? result : gate!.future;
  }
}

class FakeExpression implements ExpressionGenerator {
  UsefulExpression result = const UsefulExpression(
    'I think you want to suggest braids.',
    'I recommend braids because they are easy to maintain.',
    'Why do you recommend braids?',
  );
  ExpressionException? error;
  final calls = <(String, String)>[];
  @override
  bool get configured => true;
  @override
  Future<UsefulExpression> generate(
    String intention,
    String accessToken,
  ) async {
    calls.add((intention, accessToken));
    if (error != null) throw error!;
    return result;
  }
}

class MemoryProgressStore implements ProgressStore {
  LearnerProgress progress = const LearnerProgress();
  bool failSave = false;
  Completer<void>? saveGate;
  @override
  Future<LearnerProgress> load() async => progress;
  @override
  Future<void> save(LearnerProgress next) async {
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('Test disk full');
    progress = next;
  }

  @override
  Future<void> close() async {}
}
