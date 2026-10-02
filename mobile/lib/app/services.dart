import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/microphone.dart';
import '../core/audio/assessment_capture_store.dart';
import '../core/audio/native_microphone.dart';
import '../core/audio/recording_playback.dart';
import '../core/audio/speech_output.dart';
import '../core/curriculum/curriculum.dart';
import '../core/storage/progress_store.dart';
import '../core/storage/review_store.dart';
import '../core/storage/sqlite_progress_store.dart';
import '../core/speech/recognition.dart';
import '../core/speech/feedback.dart';
import '../core/speech/conversation.dart';
import '../core/speech/salon.dart';
import '../core/speech/expression.dart';
import '../features/conversation/conversation_controller.dart';
import '../features/assessment/assessment_controller.dart';
import '../features/assessment/assessment_playback_controller.dart';
import '../features/help_me_say_it/expression_controller.dart';
import '../features/lesson/feedback_controller.dart';
import '../features/lesson/microphone_controller.dart';
import '../features/lesson/transcription_controller.dart';

class AppServices {
  const AppServices({
    required this.curriculum,
    required this.store,
    required this.reviewStore,
    required this.progress,
    required this.microphone,
    required this.conversationMicrophone,
    required this.assessmentMicrophone,
    required this.assessmentCaptureStore,
    required this.recordingPlayback,
    required this.day5ChallengeMicrophone,
    required this.day5ChallengeCaptureStore,
    required this.day5ChallengeRecordingPlayback,
    required this.speech,
    this.recognition = const UnconfiguredSpeechRecognition(),
    this.feedback = const UnconfiguredSpeakingFeedback(),
    this.conversation = const UnconfiguredKoraConversation(),
    this.salon = const UnconfiguredKoraConversation(),
    this.expression = const UnconfiguredExpressionGenerator(),
  });
  final Curriculum curriculum;
  final ProgressStore store;
  final ReviewStore reviewStore;
  final LearnerProgress progress;
  final Microphone microphone;
  final Microphone conversationMicrophone;
  final Microphone assessmentMicrophone;
  final AssessmentCaptureStore assessmentCaptureStore;
  final RecordingPlayback recordingPlayback;
  final Microphone day5ChallengeMicrophone;
  final AssessmentCaptureStore day5ChallengeCaptureStore;
  final RecordingPlayback day5ChallengeRecordingPlayback;
  final SpeechOutput speech;
  final SpeechRecognition recognition;
  final SpeakingFeedback feedback;
  final KoraConversation conversation;
  final KoraConversation salon;
  final ExpressionGenerator expression;
}

final bootstrapProvider = FutureProvider<AppServices>((ref) async {
  final curriculum = Curriculum.parse(
    await rootBundle.loadString('assets/curriculum/alpha.json'),
  );
  // Purge prior-session voice data even if database or microphone setup fails.
  final assessmentCaptureStore = await NativeAssessmentCaptureStore.create();
  final day5ChallengeCaptureStore = await NativeAssessmentCaptureStore.create(
    type: 'day5',
  );
  final store = await SqliteProgressStore.open();
  NativeMicrophone? lessonMic;
  NativeMicrophone? dialogueMic;
  NativeMicrophone? assessmentMic;
  NativeMicrophone? day5Mic;
  try {
    final progress = await store.load();
    if (curriculum.lessons.any(
          (lesson) =>
              progress.promptForDay(lesson.day) < 0 ||
              progress.promptForDay(lesson.day) >= lesson.prompts.length,
        ) ||
        (progress.onboardingStep >= 2 &&
            progress.profession != 'beauty-cosmetology') ||
        (progress.onboardingStep >= 3 && progress.supportLanguage != 'en')) {
      throw const FormatException('Invalid local progress');
    }
    final microphone = await NativeMicrophone.create();
    lessonMic = microphone;
    final conversationMicrophone = await NativeMicrophone.create(
      folder: 'speakcraft-conversation-takes',
    );
    dialogueMic = conversationMicrophone;
    final assessmentMicrophone = await NativeMicrophone.create(
      folder: 'speakcraft-baseline-takes',
    );
    assessmentMic = assessmentMicrophone;
    final day5ChallengeMicrophone = await NativeMicrophone.create(
      folder: 'speakcraft-day5-takes',
    );
    day5Mic = day5ChallengeMicrophone;
    return AppServices(
      curriculum: curriculum,
      store: store,
      reviewStore: store,
      progress: progress,
      microphone: microphone,
      conversationMicrophone: conversationMicrophone,
      assessmentMicrophone: assessmentMicrophone,
      assessmentCaptureStore: assessmentCaptureStore,
      recordingPlayback: DeviceRecordingPlayback(),
      day5ChallengeMicrophone: day5ChallengeMicrophone,
      day5ChallengeCaptureStore: day5ChallengeCaptureStore,
      day5ChallengeRecordingPlayback: DeviceRecordingPlayback(),
      speech: DeviceSpeechOutput(),
      recognition: HttpSpeechRecognition(
        const String.fromEnvironment('SPEAKCRAFT_API_BASE_URL'),
      ),
      feedback: HttpSpeakingFeedback(
        const String.fromEnvironment('SPEAKCRAFT_API_BASE_URL'),
      ),
      conversation: HttpKoraConversation(
        const String.fromEnvironment('SPEAKCRAFT_API_BASE_URL'),
      ),
      salon: HttpSalonConversation(
        const String.fromEnvironment('SPEAKCRAFT_API_BASE_URL'),
      ),
      expression: HttpExpressionGenerator(
        const String.fromEnvironment('SPEAKCRAFT_API_BASE_URL'),
      ),
    );
  } catch (_) {
    await day5Mic?.dispose();
    await assessmentMic?.dispose();
    await dialogueMic?.dispose();
    await lessonMic?.dispose();
    await store.close();
    rethrow;
  }
});

final servicesProvider = Provider<AppServices>(
  (ref) => throw StateError('App not initialised'),
  dependencies: const [],
);
final sessionProvider = Provider<SessionController>((ref) {
  final services = ref.watch(servicesProvider);
  final session = SessionController(services.store, services.progress);
  ref.onDispose(session.dispose);
  return session;
}, dependencies: [servicesProvider]);
final reviewProvider = Provider<ReviewController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = ReviewController(
    services.reviewStore,
    services.curriculum.reviewItems,
    DateTime.now,
  );
  unawaited(controller.load());
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final microphoneProvider = Provider<MicrophoneController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = MicrophoneController(services.microphone, services.speech);
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final conversationMicrophoneProvider = Provider<MicrophoneController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = MicrophoneController(
    services.conversationMicrophone,
    services.speech,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final assessmentMicrophoneProvider = Provider<MicrophoneController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = MicrophoneController(
    services.assessmentMicrophone,
    services.speech,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final assessmentProvider = Provider<AssessmentController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = AssessmentController(
    services.assessmentCaptureStore,
    services.curriculum.baselineItems,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final assessmentPlaybackProvider = Provider<AssessmentPlaybackController>((
  ref,
) {
  final services = ref.watch(servicesProvider);
  final controller = AssessmentPlaybackController(
    services.recordingPlayback,
    services.speech,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final day5ChallengeMicrophoneProvider = Provider<MicrophoneController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = MicrophoneController(
    services.day5ChallengeMicrophone,
    services.speech,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final day5ChallengeProvider = Provider<AssessmentController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = AssessmentController(
    services.day5ChallengeCaptureStore,
    services.curriculum.day5ChallengeItems,
    label: 'Day-5 challenge',
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final day5ChallengePlaybackProvider = Provider<AssessmentPlaybackController>((
  ref,
) {
  final services = ref.watch(servicesProvider);
  final controller = AssessmentPlaybackController(
    services.day5ChallengeRecordingPlayback,
    services.speech,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final transcriptionProvider = Provider<TranscriptionController>((ref) {
  final controller = TranscriptionController(
    ref.watch(servicesProvider).recognition,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final feedbackProvider = Provider<FeedbackController>((ref) {
  final controller = FeedbackController(ref.watch(servicesProvider).feedback);
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final conversationProvider = Provider<ConversationController>((ref) {
  final services = ref.watch(servicesProvider);
  final authored = services.curriculum.dayOne.conversation!;
  final controller = ConversationController(
    provider: services.conversation,
    lessonId: services.curriculum.dayOne.id,
    opening: authored.opening,
    turnLimit: authored.turnLimit,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
final salonConversationProvider =
    Provider.family<ConversationController, String>((ref, scenarioId) {
      final services = ref.watch(servicesProvider);
      final scenario = services.curriculum.scenarioForId(scenarioId)!;
      final controller = ConversationController(
        provider: services.salon,
        lessonId: scenario.id,
        opening: scenario.customerOpening,
        turnLimit: scenario.turnLimit,
      );
      ref.onDispose(controller.dispose);
      return controller;
    }, dependencies: [servicesProvider]);
final expressionProvider = Provider<ExpressionController>((ref) {
  final controller = ExpressionController(
    ref.watch(servicesProvider).expression,
  );
  ref.onDispose(controller.dispose);
  return controller;
}, dependencies: [servicesProvider]);
