import 'dart:async';

import 'package:speakcraft/core/audio/microphone.dart';
import 'package:speakcraft/core/audio/assessment_capture_store.dart';
import 'package:speakcraft/core/audio/recording_playback.dart';
import 'package:speakcraft/core/audio/speech_output.dart';
import 'package:speakcraft/core/storage/progress_store.dart';
import 'package:speakcraft/core/storage/review_store.dart';
import 'package:speakcraft/core/speech/recognition.dart';
import 'package:speakcraft/core/speech/feedback.dart';
import 'package:speakcraft/core/speech/conversation.dart';
import 'package:speakcraft/core/speech/expression.dart';

class TestStopwatch extends Stopwatch {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
  @override
  void reset() => value = Duration.zero;
  @override
  void start() {}
  @override
  void stop() {}
}

/// Test-only adapters; production always uses native recording and SQLite.
class FakeMicrophone implements Microphone {
  bool permission = true;
  bool failStart = false;
  bool failStop = false;
  bool failDiscard = false;
  int starts = 0;
  int stops = 0;
  int discards = 0;
  Completer<void>? startGate;
  Completer<void>? stopGate;
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
    if (stopGate != null) await stopGate!.future;
    if (failStop) throw StateError('Test stop failure');
    return '/test/recording.m4a';
  }

  @override
  Future<void> discard() async {
    discards++;
    if (failDiscard) throw StateError('Test cleanup failure');
  }

  @override
  Future<void> dispose() async {
    await events.close();
  }
}

class FakeSpeech implements SpeechOutput {
  final spoken = <String>[];
  final slowFlags = <bool>[];
  bool unavailable = false;
  Completer<void>? speakGate;
  int stops = 0;
  @override
  Future<void> speak(String text, {bool slow = false}) async {
    if (unavailable) throw StateError('No test voice');
    spoken.add(text);
    slowFlags.add(slow);
    if (speakGate != null) await speakGate!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

class FakeAssessmentCaptureStore implements AssessmentCaptureStore {
  FakeAssessmentCaptureStore({this.folder = 'baseline'});
  final String folder;
  final captures = <String, String>{};
  bool failSave = false;
  bool failClear = false;
  Completer<void>? saveGate;

  @override
  Future<String> save(String itemId, String recordingPath) async {
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('Test assessment save failure');
    final path = '/test/$folder/$itemId.m4a';
    captures[itemId] = path;
    return path;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Test assessment clear failure');
    captures.clear();
  }
}

class FakeRecordingPlayback implements RecordingPlayback {
  final events = StreamController<void>.broadcast();
  final paths = <String>[];
  int stops = 0;
  bool failPlay = false;
  bool failStop = false;
  Completer<void>? playGate;
  bool playing = false;

  @override
  Stream<void> get completed => events.stream;

  @override
  Future<void> play(String path) async {
    if (playGate != null) await playGate!.future;
    if (failPlay) throw StateError('Test playback failure');
    paths.add(path);
    playing = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    if (failStop) throw StateError('Test playback stop failure');
    playing = false;
  }

  void complete() {
    playing = false;
    events.add(null);
  }

  @override
  Future<void> dispose() async {
    await events.close();
  }
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

class MemoryProgressStore implements ProgressStore, ReviewStore {
  LearnerProgress progress = const LearnerProgress();
  Map<String, ReviewProgress> review = {};
  bool failSave = false;
  bool failClear = false;
  bool failReviewSave = false;
  bool failReviewLoad = false;
  Completer<void>? reviewSaveGate;
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
  Future<void> clear() async {
    if (failClear) throw StateError('Test disk failure');
    progress = const LearnerProgress();
    review = {};
  }

  @override
  Future<Map<String, ReviewProgress>> loadReview() async {
    if (failReviewLoad) throw StateError('Test review read failure');
    return Map.of(review);
  }

  @override
  Future<void> saveReview(String itemId, ReviewProgress next) async {
    if (reviewSaveGate != null) await reviewSaveGate!.future;
    if (failReviewSave) throw StateError('Test review write failure');
    review = {...review, itemId: next};
  }

  @override
  Future<void> close() async {}
}
