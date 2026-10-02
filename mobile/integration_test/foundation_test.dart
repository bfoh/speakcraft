import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speakcraft/app/services.dart';
import 'package:speakcraft/app/speakcraft_app.dart';
import 'package:speakcraft/core/audio/native_microphone.dart';
import 'package:speakcraft/core/audio/speech_output.dart';
import 'package:speakcraft/core/curriculum/curriculum.dart';
import 'package:speakcraft/core/storage/progress_store.dart';
import 'package:speakcraft/core/storage/sqlite_progress_store.dart';
import 'package:speakcraft/core/speech/recognition.dart';
import 'package:speakcraft/core/speech/feedback.dart';
import 'package:speakcraft/core/speech/conversation.dart';
import 'package:speakcraft/core/speech/salon.dart';
import 'package:speakcraft/core/speech/expression.dart';
import 'package:speakcraft/features/lesson/microphone_controller.dart';
import 'package:speakcraft/features/lesson/transcription_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native onboarding, capture, feedback and Kora conversation', (
    tester,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    String? receivedAuthorization;
    var receivedBytes = 0;
    String? feedbackBody;
    String? conversationBody;
    String? salonBody;
    String? expressionBody;
    server.listen((request) async {
      final parts = await request.toList();
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/v1/speech/evaluate') {
        feedbackBody = String.fromCharCodes(parts.expand((bytes) => bytes));
        request.response.write(
          '{"outcome":"clear","feedback":"I understood you clearly.","example":null}',
        );
      } else if (request.uri.path == '/v1/kora/respond') {
        conversationBody = String.fromCharCodes(parts.expand((bytes) => bytes));
        request.response.write(
          '{"reply":"Nice to meet you.","next_question":"Why did you choose it?"}',
        );
      } else if (request.uri.path == '/v1/salon/respond') {
        salonBody = String.fromCharCodes(parts.expand((bytes) => bytes));
        request.response.write(
          '{"customer_reply":"I like medium braids.","next_question":"Could you check the price?"}',
        );
      } else if (request.uri.path == '/v1/help-me-say-it') {
        expressionBody = String.fromCharCodes(parts.expand((bytes) => bytes));
        request.response.write(
          '{"understood_meaning":"I think you want to talk about your studies.","expression":"I study beauty and cosmetology.","customer_cue":"What do you study?"}',
        );
      } else {
        receivedAuthorization = request.headers.value(
          HttpHeaders.authorizationHeader,
        );
        receivedBytes = parts.fold(0, (sum, bytes) => sum + bytes.length);
        request.response.write(
          '{"transcript":"I study beauty and cosmetology."}',
        );
      }
      await request.response.close();
    });
    final path = '${(await getTemporaryDirectory()).path}/sprint-1-smoke.db';
    var store = await SqliteProgressStore.open(path: path);
    await store.save(const LearnerProgress());
    final services = AppServices(
      curriculum: Curriculum.parse(
        await rootBundle.loadString('assets/curriculum/alpha.json'),
      ),
      store: store,
      reviewStore: store,
      progress: await store.load(),
      microphone: await NativeMicrophone.create(),
      conversationMicrophone: await NativeMicrophone.create(
        folder: 'speakcraft-conversation-takes',
      ),
      speech: DeviceSpeechOutput(),
      recognition: HttpSpeechRecognition('http://127.0.0.1:${server.port}'),
      feedback: HttpSpeakingFeedback('http://127.0.0.1:${server.port}'),
      conversation: HttpKoraConversation('http://127.0.0.1:${server.port}'),
      salon: HttpSalonConversation('http://127.0.0.1:${server.port}'),
      expression: HttpExpressionGenerator('http://127.0.0.1:${server.port}'),
    );
    final container = ProviderContainer(
      overrides: [servicesProvider.overrideWithValue(services)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeakCraftApp(),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String text) async {
      final finder = find.text(text);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    for (final label in [
      'Get started',
      'Continue',
      'Continue in English',
      'Meet your first lesson',
      'Go to Home',
      'Open Day 1',
    ]) {
      await tap(label);
    }
    await tap('Next practice');
    expect((await store.load()).dayOnePrompt, 1);
    // Grant permission with adb/simctl before this test, or accept the OS prompt.
    await tap('Enable microphone');
    final microphoneController = container.read(microphoneProvider);
    for (
      var attempt = 0;
      attempt < 50 &&
          microphoneController.state == MicrophoneState.requestingPermission;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      microphoneController.state,
      MicrophoneState.ready,
      reason: 'Grant OS microphone permission before the native test',
    );
    await tap('Start recording');
    for (
      var attempt = 0;
      attempt < 50 && microphoneController.state == MicrophoneState.processing;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      microphoneController.state,
      MicrophoneState.recording,
      reason: 'Native recorder should enter recording after Start recording',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      microphoneController.state,
      MicrophoneState.recording,
      reason: 'Native capture should remain active until Stop recording',
    );
    await tap('Stop recording');
    final recording = container.read(microphoneProvider).recordingPath;
    expect(recording, isNotNull);
    expect(await File(recording!).length(), greaterThan(0));
    await tap('Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-test');
    await tap('Continue');
    final transcription = container.read(transcriptionProvider);
    for (
      var attempt = 0;
      attempt < 50 && transcription.state == TranscriptionState.sending;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(transcription.state, TranscriptionState.success);
    expect(transcription.transcript, 'I study beauty and cosmetology.');
    expect(receivedAuthorization, 'Bearer pilot-test');
    expect(receivedBytes, greaterThan(await File(recording).length()));
    await tap('Help me say it better');
    expect(find.text('I understood you clearly.'), findsOneWidget);
    expect(feedbackBody, contains('introduce-study'));
    expect(feedbackBody, contains('I study beauty and cosmetology.'));
    await tap('Back to Home');
    await tap('Open Day 1');
    expect(container.read(microphoneProvider).recordingPath, recording);
    await tap('Back to Home');
    await tap('Talk with Kora');
    await tap('Enable microphone');
    final conversationMic = container.read(conversationMicrophoneProvider);
    for (
      var attempt = 0;
      attempt < 50 &&
          conversationMic.state == MicrophoneState.requestingPermission;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(conversationMic.state, MicrophoneState.ready);
    await tap('Start recording');
    await tester.pump(const Duration(seconds: 2));
    await tap('Stop recording');
    await tap('Hear my words');
    await tap('Send reply to Kora');
    expect(
      find.text('Nice to meet you. Why did you choose it?'),
      findsOneWidget,
    );
    expect(conversationBody, contains('day-1'));
    expect(conversationBody, contains('I study beauty and cosmetology.'));
    await tap('Back to Home');
    await tap('Open AI Salon');
    await tap('Enable microphone');
    for (
      var attempt = 0;
      attempt < 50 &&
          conversationMic.state == MicrophoneState.requestingPermission;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(conversationMic.state, MicrophoneState.ready);
    await tap('Start recording');
    await tester.pump(const Duration(seconds: 2));
    await tap('Stop recording');
    await tap('Hear my words');
    await tap('Send reply to customer');
    expect(
      find.text('I like medium braids. Could you check the price?'),
      findsOneWidget,
    );
    expect(salonBody, contains('friendly-braids-price'));
    expect(salonBody, contains('"speaker":"customer"'));
    await tap('Back to Home');
    await tap('Open Help Me Say It');
    await tap('Enable microphone');
    for (
      var attempt = 0;
      attempt < 50 &&
          conversationMic.state == MicrophoneState.requestingPermission;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(conversationMic.state, MicrophoneState.ready);
    await tap('Start recording');
    await tester.pump(const Duration(seconds: 2));
    await tap('Stop recording');
    await tap('Hear my words');
    await tap('Ask Kora for English');
    expect(expressionBody, contains('I study beauty and cosmetology.'));
    expect(find.text('2 • Listen and repeat'), findsOneWidget);
    await tap('Listen to phrase');
    await tap('Enable microphone');
    await tap('Start recording');
    await tester.pump(const Duration(seconds: 2));
    await tap('Stop recording');
    await tap('Hear my words');
    await tap('Continue to customer');
    expect(find.text('3 • Answer the customer'), findsOneWidget);
    await tap('Listen to customer');
    await tap('Enable microphone');
    await tap('Start recording');
    await tester.pump(const Duration(seconds: 2));
    await tap('Stop recording');
    await tap('Hear my words');
    await tap('Finish practice');
    expect(find.text('You practised the phrase'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap('Open Day 1');
    expect(container.read(microphoneProvider).recordingPath, recording);
    expect(await File(recording).exists(), isTrue);
    await tap('Delete recording');
    expect(await File(recording).exists(), isFalse);
    await tap('Back to Home');
    await tap('My Words');
    await tap('Listen and repeat');
    await tap('Felt easy');
    expect((await store.loadReview())['my-course']!.attempts, 1);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap('Open Day 2');
    expect(find.text('Day 2 • Practice 1 of 3'), findsOneWidget);
    await tap('Next practice');
    expect((await store.load()).promptForDay(2), 1);
    expect((await store.loadReview())['my-course']!.easeStage, 1);
    await store.close();
    store = await SqliteProgressStore.open(path: path);
    expect((await store.load()).dayOnePrompt, 1);
    expect((await store.load()).promptForDay(2), 1);
    await store.close();
    container.dispose();
    await server.close(force: true);
  });
}
