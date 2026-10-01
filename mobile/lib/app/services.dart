import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/microphone.dart';
import '../core/audio/native_microphone.dart';
import '../core/audio/speech_output.dart';
import '../core/curriculum/curriculum.dart';
import '../core/storage/progress_store.dart';
import '../core/storage/sqlite_progress_store.dart';
import '../core/speech/recognition.dart';
import '../features/lesson/microphone_controller.dart';
import '../features/lesson/transcription_controller.dart';

class AppServices {
  const AppServices({
    required this.curriculum,
    required this.store,
    required this.progress,
    required this.microphone,
    required this.speech,
    this.recognition = const UnconfiguredSpeechRecognition(),
  });
  final Curriculum curriculum;
  final ProgressStore store;
  final LearnerProgress progress;
  final Microphone microphone;
  final SpeechOutput speech;
  final SpeechRecognition recognition;
}

final bootstrapProvider = FutureProvider<AppServices>((ref) async {
  final curriculum = Curriculum.parse(
    await rootBundle.loadString('assets/curriculum/alpha.json'),
  );
  final store = await SqliteProgressStore.open();
  try {
    final progress = await store.load();
    if (progress.dayOnePrompt >= curriculum.dayOne.prompts.length ||
        (progress.onboardingStep >= 2 &&
            progress.profession != 'beauty-cosmetology') ||
        (progress.onboardingStep >= 3 && progress.supportLanguage != 'en')) {
      throw const FormatException('Invalid local progress');
    }
    final microphone = await NativeMicrophone.create();
    return AppServices(
      curriculum: curriculum,
      store: store,
      progress: progress,
      microphone: microphone,
      speech: DeviceSpeechOutput(),
      recognition: HttpSpeechRecognition(
        const String.fromEnvironment('SPEAKCRAFT_API_BASE_URL'),
      ),
    );
  } catch (_) {
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
final microphoneProvider = Provider<MicrophoneController>((ref) {
  final services = ref.watch(servicesProvider);
  final controller = MicrophoneController(services.microphone, services.speech);
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
