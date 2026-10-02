import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakcraft/app/router.dart';
import 'package:speakcraft/app/services.dart';
import 'package:speakcraft/app/speakcraft_app.dart';
import 'package:speakcraft/core/curriculum/curriculum.dart';
import 'package:speakcraft/core/storage/progress_store.dart';
import 'package:speakcraft/core/speech/recognition.dart';
import 'package:speakcraft/core/speech/feedback.dart';
import 'package:speakcraft/core/speech/conversation.dart';
import 'package:speakcraft/core/speech/expression.dart';
import 'package:speakcraft/features/lesson/microphone_controller.dart';
import 'package:speakcraft/features/progress/confidence_check_in.dart';

import 'support/fakes.dart';

void main() {
  late MemoryProgressStore store;
  late FakeMicrophone mic;
  late FakeSpeech speech;
  late FakeAssessmentCaptureStore assessmentCapture;
  late FakeAssessmentCaptureStore day5Capture;
  late FakeRecordingPlayback recordingPlayback;
  late FakeRecordingPlayback day5Playback;
  late FakeMicrophone baselineMic;
  late FakeMicrophone day5Mic;
  late ProviderContainer container;

  Future<void> launch(
    WidgetTester tester, {
    LearnerProgress progress = const LearnerProgress(),
    SpeechRecognition recognition = const UnconfiguredSpeechRecognition(),
    SpeakingFeedback feedback = const UnconfiguredSpeakingFeedback(),
    KoraConversation conversation = const UnconfiguredKoraConversation(),
    KoraConversation salon = const UnconfiguredKoraConversation(),
    ExpressionGenerator expression = const UnconfiguredExpressionGenerator(),
    TestStopwatch? salonClock,
  }) async {
    store = MemoryProgressStore()..progress = progress;
    mic = FakeMicrophone();
    speech = FakeSpeech();
    assessmentCapture = FakeAssessmentCaptureStore();
    day5Capture = FakeAssessmentCaptureStore(folder: 'day5');
    recordingPlayback = FakeRecordingPlayback();
    day5Playback = FakeRecordingPlayback();
    baselineMic = FakeMicrophone();
    day5Mic = FakeMicrophone();
    final salonController = salonClock == null
        ? null
        : MicrophoneController(FakeMicrophone(), speech, clock: salonClock);
    if (salonController != null) addTearDown(salonController.dispose);
    container = ProviderContainer(
      overrides: [
        if (salonController != null)
          conversationMicrophoneProvider.overrideWithValue(salonController),
        servicesProvider.overrideWithValue(
          AppServices(
            curriculum: Curriculum.parse(
              File('assets/curriculum/alpha.json').readAsStringSync(),
            ),
            store: store,
            reviewStore: store,
            progress: progress,
            microphone: mic,
            conversationMicrophone: FakeMicrophone(),
            assessmentMicrophone: baselineMic,
            assessmentCaptureStore: assessmentCapture,
            recordingPlayback: recordingPlayback,
            day5ChallengeMicrophone: day5Mic,
            day5ChallengeCaptureStore: day5Capture,
            day5ChallengeRecordingPlayback: day5Playback,
            speech: speech,
            recognition: recognition,
            feedback: feedback,
            conversation: conversation,
            salon: salon,
            expression: expression,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpeakCraftApp(),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(container.dispose);
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  const returning = LearnerProgress(
    onboardingStep: 5,
    profession: 'beauty-cosmetology',
    supportLanguage: 'en',
  );

  testWidgets('production bootstrap resolves scoped services', (tester) async {
    final localStore = MemoryProgressStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => AppServices(
              curriculum: Curriculum.parse(
                File('assets/curriculum/alpha.json').readAsStringSync(),
              ),
              store: localStore,
              reviewStore: localStore,
              progress: const LearnerProgress(),
              microphone: FakeMicrophone(),
              conversationMicrophone: FakeMicrophone(),
              assessmentMicrophone: FakeMicrophone(),
              assessmentCaptureStore: FakeAssessmentCaptureStore(),
              recordingPlayback: FakeRecordingPlayback(),
              day5ChallengeMicrophone: FakeMicrophone(),
              day5ChallengeCaptureStore: FakeAssessmentCaptureStore(),
              day5ChallengeRecordingPlayback: FakeRecordingPlayback(),
              speech: FakeSpeech(),
            ),
          ),
        ],
        child: const SpeakCraftBootstrap(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Real English.\nReal skills.'), findsOneWidget);
    await tap(tester, 'Get started');
    expect(find.text('What do you study?'), findsOneWidget);
  });

  testWidgets(
    'onboarding through Day 1, capture, navigation and saved position',
    (tester) async {
      await launch(tester);
      await tap(tester, 'Get started');
      expect(
        find.text('Beauty & Cosmetology\nYour Alpha pathway'),
        findsOneWidget,
      );
      await tap(tester, 'Continue');
      await tap(tester, 'Continue in English');
      expect(find.text('Meet Kora'), findsOneWidget);
      await tap(tester, 'Meet your first lesson');
      expect(find.textContaining('No result is recorded yet'), findsOneWidget);
      await tap(tester, 'Go to Home');
      expect(store.progress.onboarded, isTrue);
      await tap(tester, 'Open Day 1');
      await tap(tester, 'Listen to example');
      expect(speech.spoken.last, 'My name is Ama.');
      expect(speech.slowFlags.last, isFalse);
      await tap(tester, 'Listen slowly');
      expect(speech.spoken.last, 'My name is Ama.');
      expect(speech.slowFlags.last, isTrue);
      await tap(tester, 'Enable microphone');
      expect(mic.starts, 0);
      await tap(tester, 'Start recording');
      expect(find.text('Stop recording'), findsOneWidget);
      await tap(tester, 'Stop recording');
      expect(
        find.textContaining('Your recording is saved for this session'),
        findsOneWidget,
      );
      await tap(tester, 'Back to Home');
      await tap(tester, 'Open Day 1');
      expect(find.textContaining('Your recording is saved'), findsOneWidget);
      await tap(tester, 'Next practice');
      expect(store.progress.dayOnePrompt, 1);
      expect(find.text('Say what you study.'), findsOneWidget);
    },
  );

  testWidgets('learner explicitly sends one take and sees tentative words', (
    tester,
  ) async {
    final recognition = FakeRecognition();
    await launch(tester, progress: returning, recognition: recognition);
    await tap(tester, 'Open Day 1');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    expect(recognition.calls, isEmpty);
    await tap(tester, 'Hear my words');
    expect(find.text('Connect speech recognition'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    expect(recognition.calls, [('/test/recording.m4a', 'pilot-access-code')]);
    expect(find.text('My name is Ama.'), findsNWidgets(2));
    expect(find.textContaining('can make mistakes'), findsOneWidget);
    await tap(tester, 'Next practice');
    expect(find.text('My name is Ama.'), findsNothing);
  });

  testWidgets('offline upload keeps the recording for retry', (tester) async {
    final recognition = FakeRecognition()
      ..error = const SpeechRecognitionException(SpeechProblem.offline);
    await launch(tester, progress: returning, recognition: recognition);
    await tap(tester, 'Open Day 1');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    expect(find.textContaining("couldn't connect"), findsOneWidget);
    expect(find.text('Delete recording'), findsOneWidget);
    recognition.error = null;
    await tap(tester, 'Hear my words');
    expect(recognition.calls.length, 2);
    expect(find.text('My name is Ama.'), findsNWidgets(2));
  });

  testWidgets('learner asks for feedback and can listen to one model', (
    tester,
  ) async {
    final recognition = FakeRecognition();
    final feedback = FakeFeedback();
    await launch(
      tester,
      progress: returning,
      recognition: recognition,
      feedback: feedback,
    );
    await tap(tester, 'Open Day 1');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    expect(feedback.calls, isEmpty);
    await tap(tester, 'Help me say it better');
    expect(feedback.calls, [
      ('day-1', 'introduce-name', 'My name is Ama.', 'pilot-access-code'),
    ]);
    expect(
      find.text('Good start. Make your sentence clearer.'),
      findsOneWidget,
    );
    await tap(tester, 'Listen to Kora');
    expect(speech.spoken.last, 'Good start. Make your sentence clearer.');
    await tap(tester, 'Listen and try again');
    expect(speech.spoken.last, 'My name is Ama.');
    await tap(tester, 'Next practice');
    expect(find.text('Good start. Make your sentence clearer.'), findsNothing);
  });

  testWidgets('feedback connection failure keeps transcript and take', (
    tester,
  ) async {
    final feedback = FakeFeedback()
      ..error = const FeedbackException(FeedbackProblem.offline);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      feedback: feedback,
    );
    await tap(tester, 'Open Day 1');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Help me say it better');
    expect(
      find.textContaining("couldn't connect for feedback"),
      findsOneWidget,
    );
    expect(find.text('Delete recording'), findsOneWidget);
    feedback.error = null;
    await tap(tester, 'Help me say it better');
    expect(feedback.calls.length, 2);
  });

  testWidgets('rejected feedback code can be replaced without rerecording', (
    tester,
  ) async {
    final feedback = FakeFeedback()
      ..error = const FeedbackException(FeedbackProblem.accessDenied);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      feedback: feedback,
    );
    await tap(tester, 'Open Day 1');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'old-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Help me say it better');
    expect(find.textContaining('stopped working'), findsOneWidget);
    feedback.error = null;
    await tap(tester, 'Help me say it better');
    expect(find.text('Connect speech recognition'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'new-code');
    await tap(tester, 'Continue');
    expect(feedback.calls.last.$4, 'new-code');
    expect(find.text('Delete recording'), findsOneWidget);
  });

  testWidgets('learner completes a short spoken Kora exchange', (tester) async {
    final recognition = FakeRecognition();
    final conversation = FakeConversation();
    await launch(
      tester,
      progress: returning,
      recognition: recognition,
      conversation: conversation,
    );
    await tap(tester, 'Talk with Kora');
    expect(
      find.text("Hello! I'm Kora. Tell me your name and what you study."),
      findsOneWidget,
    );
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    expect(conversation.calls, isEmpty);
    await tap(tester, 'Send reply to Kora');
    expect(conversation.calls.length, 1);
    expect(conversation.calls.first.$2.first.speaker, ConversationSpeaker.kora);
    expect(conversation.calls.first.$3, 'My name is Ama.');
    expect(
      find.text('Nice to meet you. Why did you choose it?'),
      findsOneWidget,
    );
    conversation.result = const KoraReply('Thank you for sharing.', null);
    recognition.result = 'I want to help people feel confident.';
    await tap(tester, 'Prepare next answer');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tap(tester, 'Send reply to Kora');
    expect(conversation.calls.length, 2);
    expect(conversation.calls.last.$2.length, 3);
    expect(find.textContaining('Conversation finished'), findsOneWidget);
    await tap(tester, 'Start conversation again');
    expect(find.text('Nice to meet you. Why did you choose it?'), findsNothing);
  });

  testWidgets('offline conversation keeps the answer for retry', (
    tester,
  ) async {
    final conversation = FakeConversation()
      ..error = const ConversationException(ConversationProblem.offline);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      conversation: conversation,
    );
    await tap(tester, 'Talk with Kora');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Send reply to Kora');
    expect(find.textContaining("couldn't connect"), findsOneWidget);
    expect(find.text('Delete answer'), findsOneWidget);
    conversation.error = null;
    await tap(tester, 'Send reply to Kora');
    expect(conversation.calls.length, 2);
  });

  testWidgets('Kora dialogue fits small screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, progress: returning, conversation: FakeConversation());
    await tap(tester, 'Talk with Kora');
    expect(tester.takeException(), isNull);
    await tap(tester, 'Enable microphone');
    expect(tester.takeException(), isNull);
  });

  testWidgets('learner speaks with first simulated salon customer', (
    tester,
  ) async {
    final recognition = FakeRecognition()
      ..result = 'Welcome. What kind of braids would you like?';
    final salon = FakeConversation()
      ..result = const KoraReply(
        'I like medium braids.',
        'Could you check the price?',
      );
    await launch(
      tester,
      progress: returning,
      recognition: recognition,
      salon: salon,
    );
    await tap(tester, 'Open AI Salon');
    expect(find.text('AI Salon'), findsOneWidget);
    expect(
      find.text("Hello. I'd like braids. How much would they cost?"),
      findsOneWidget,
    );
    expect(find.textContaining('No salon price is set'), findsOneWidget);
    await tap(tester, 'Listen to customer');
    expect(
      speech.spoken.last,
      "Hello. I'd like braids. How much would they cost?",
    );
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    expect(salon.calls, isEmpty);
    await tap(tester, 'Send reply to customer');
    expect(salon.calls.first.$1, 'friendly-braids-price');
    expect(
      salon.calls.first.$3,
      'Welcome. What kind of braids would you like?',
    );
    expect(
      find.text('I like medium braids. Could you check the price?'),
      findsOneWidget,
    );
  });

  testWidgets('offline salon reply preserves the current answer', (
    tester,
  ) async {
    final salon = FakeConversation()
      ..error = const ConversationException(ConversationProblem.offline);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      salon: salon,
    );
    await tap(tester, 'Open AI Salon');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Send reply to customer');
    expect(find.textContaining("couldn't connect"), findsOneWidget);
    expect(find.text('Delete answer'), findsOneWidget);
    salon.error = null;
    await tap(tester, 'Send reply to customer');
    expect(salon.calls.length, 2);
  });

  testWidgets('Day 3 and Day 5 open their distinct customer scenarios', (
    tester,
  ) async {
    final salon = FakeConversation();
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      salon: salon,
    );
    await tap(tester, 'Open Day 3');
    await tap(tester, 'Practise in AI Salon');
    expect(
      find.text('Hello. I need a hairstyle for graduation. Can you help me?'),
      findsOneWidget,
    );
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Send reply to customer');
    expect(salon.calls.single.$1, 'welcome-needs-consultation');
    expect(store.progress.bestSalonTurns('welcome-needs-consultation'), 0);
    await tap(tester, 'Back to Home');
    await tap(tester, 'Open Day 5');
    await tap(tester, 'Practise in AI Salon');
    expect(
      find.text(
        'Hello. I want a hairstyle that is easy to maintain. Can you help me?',
      ),
      findsOneWidget,
    );
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tap(tester, 'Send reply to customer');
    expect(salon.calls.last.$1, 'complete-salon-conversation');
    expect(find.text('Turn 2 of 6'), findsOneWidget);
    expect(store.progress.bestSalonTurns('complete-salon-conversation'), 0);
  });

  testWidgets('early salon ending saves its actual reply count for review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final salon = FakeConversation()
      ..result = const KoraReply('Thank you for your help.', null);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      salon: salon,
    );
    await tap(tester, 'Open Day 5');
    await tap(tester, 'Practise in AI Salon');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Send reply to customer');
    expect(store.progress.bestSalonTurns('complete-salon-conversation'), 1);
    expect(
      find.text('You recorded answers for 0 seconds in this rehearsal.'),
      findsOneWidget,
    );
    expect(
      find.text('You answered 1 of 6 customer turns in this rehearsal.'),
      findsOneWidget,
    );
    expect(find.text('These are practice goals, not a score.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tap(tester, 'Hear practice goals');
    expect(speech.spoken.last, contains('Greet the customer.'));
    await tap(tester, 'Back to Home');
    expect(find.text('AI Salon replies saved: 1 of 6'), findsOneWidget);
    await tap(tester, 'My practice');
    expect(find.text('AI Salon replies saved: 1 of 6'), findsOneWidget);
  });

  testWidgets('sent salon answer records measured time on this phone', (
    tester,
  ) async {
    final clock = TestStopwatch();
    final salon = FakeConversation()
      ..result = const KoraReply('Thank you for your help.', null);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      salon: salon,
      salonClock: clock,
    );
    await tap(tester, 'Open Day 3');
    await tap(tester, 'Practise in AI Salon');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    clock.value = const Duration(seconds: 15);
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Send reply to customer');
    expect(
      store.progress.longestSalonRecordedSeconds('welcome-needs-consultation'),
      15,
    );
    expect(
      find.text('You recorded answers for 15 seconds in this rehearsal.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not time the whole customer consultation'),
      findsOneWidget,
    );
    await tap(tester, 'Back to Home');
    expect(
      find.text('Most time recording answers: 15 seconds'),
      findsOneWidget,
    );
  });

  testWidgets('failed rehearsal save keeps dialogue and offers retry', (
    tester,
  ) async {
    final salon = FakeConversation()
      ..result = const KoraReply('Thank you for your help.', null);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      salon: salon,
    );
    await tap(tester, 'Open Day 3');
    await tap(tester, 'Practise in AI Salon');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    store.failSave = true;
    await tap(tester, 'Send reply to customer');
    expect(store.progress.bestSalonTurns('welcome-needs-consultation'), 0);
    expect(find.text('Save rehearsal'), findsOneWidget);
    expect(find.text('These are practice goals, not a score.'), findsOneWidget);
    expect(find.textContaining("couldn't save your rehearsal"), findsOneWidget);
    store.failSave = false;
    await tap(tester, 'Save rehearsal');
    expect(store.progress.bestSalonTurns('welcome-needs-consultation'), 1);
    expect(find.text('Save rehearsal'), findsNothing);
  });

  testWidgets('four-turn Day 3 rehearsal saves four replies, not a score', (
    tester,
  ) async {
    final salon = FakeConversation();
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      salon: salon,
    );
    await tap(tester, 'Open Day 3');
    await tap(tester, 'Practise in AI Salon');
    await tap(tester, 'Enable microphone');
    for (var turn = 1; turn <= 4; turn++) {
      if (turn > 1) await tap(tester, 'Prepare next answer');
      await tap(tester, 'Start recording');
      await tap(tester, 'Stop recording');
      await tap(tester, 'Hear my words');
      if (turn == 1) {
        await tester.enterText(find.byType(TextField), 'pilot-access-code');
        await tap(tester, 'Continue');
      }
      if (turn == 4) {
        salon.result = const KoraReply('Thank you for your help.', null);
      }
      await tap(tester, 'Send reply to customer');
      if (turn < 4) {
        expect(store.progress.bestSalonTurns('welcome-needs-consultation'), 0);
      }
    }
    expect(store.progress.bestSalonTurns('welcome-needs-consultation'), 4);
    expect(
      find.text('You answered 4 of 4 customer turns in this rehearsal.'),
      findsOneWidget,
    );
    expect(find.text('These are practice goals, not a score.'), findsOneWidget);
  });

  testWidgets('Help Me Say It flows through expression, repeat and role-play', (
    tester,
  ) async {
    final recognition = FakeRecognition()..result = 'I want to suggest braids';
    final expression = FakeExpression();
    await launch(
      tester,
      progress: returning,
      recognition: recognition,
      expression: expression,
    );
    await tap(tester, 'Open Help Me Say It');
    expect(find.text('1 • Say what you mean'), findsOneWidget);
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    expect(expression.calls, isEmpty);
    await tap(tester, 'Ask Kora for English');
    expect(expression.calls.single.$1, 'I want to suggest braids');
    expect(find.text('2 • Listen and repeat'), findsOneWidget);
    await tap(tester, 'Listen to phrase');
    expect(speech.spoken.last, expression.result.expression);
    recognition.result = expression.result.expression;
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tap(tester, 'Continue to customer');
    expect(find.text('3 • Answer the customer'), findsOneWidget);
    await tap(tester, 'Listen to customer');
    expect(speech.spoken.last, expression.result.customerCue);
    recognition.result = 'Because braids are easy to maintain';
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tap(tester, 'Finish practice');
    expect(find.text('You practised the phrase'), findsOneWidget);
    expect(find.text('Because braids are easy to maintain'), findsOneWidget);
  });

  testWidgets('Help Me Say It keeps the take after offline generation', (
    tester,
  ) async {
    final expression = FakeExpression()
      ..error = const ExpressionException(ExpressionProblem.offline);
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      expression: expression,
    );
    await tap(tester, 'Open Help Me Say It');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Ask Kora for English');
    expect(find.textContaining('Your recording is still here'), findsOneWidget);
    expression.error = null;
    await tap(tester, 'Ask Kora for English');
    expect(find.text('2 • Listen and repeat'), findsOneWidget);
  });

  testWidgets('each open day uses its own prompt and saved position', (
    tester,
  ) async {
    final feedback = FakeFeedback();
    await launch(
      tester,
      progress: returning,
      recognition: FakeRecognition(),
      feedback: feedback,
    );
    await tap(tester, 'Open Day 2');
    expect(find.text('My Salon'), findsOneWidget);
    expect(find.text('Day 2 • Practice 1 of 3'), findsOneWidget);
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    await tap(tester, 'Help me say it better');
    expect(feedback.calls.last.$1, 'day-2');
    expect(feedback.calls.last.$2, 'salon-object');
    await tap(tester, 'Next practice');
    expect(store.progress.promptForDay(2), 1);
    await tap(tester, 'Back to Home');
    await tap(tester, 'Open Day 3');
    expect(find.text('Day 3 • Practice 1 of 3'), findsOneWidget);
    expect(find.text('Delete recording'), findsNothing);
    await tap(tester, 'Back to Home');
    await tap(tester, 'Open Day 2');
    expect(find.text('Day 2 • Practice 2 of 3'), findsOneWidget);
    await tap(tester, 'Back to Home');
    await tap(tester, 'Open Day 5');
    expect(find.text('Day 5 • Practice 1 of 4'), findsOneWidget);
    expect(find.text('Practise in AI Salon'), findsOneWidget);
  });

  testWidgets('a skipped step stays unfinished until its recording is saved', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'Open Day 2');
    await tap(tester, 'Next practice');
    expect(store.progress.attemptedPromptIds, isEmpty);
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Next practice');
    expect(store.progress.attemptedPromptIds, {'salon-product'});
    expect(find.text('1 of 3 speaking steps saved'), findsOneWidget);
    expect(find.text('Practice steps finished'), findsNothing);
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Save this practice');
    expect(store.progress.attemptedPromptIds, {
      'salon-product',
      'salon-object-purpose',
    });
    expect(find.text('Practice steps finished'), findsNothing);
    await tap(tester, 'Practise from the start');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Next practice');
    expect(
      store.progress.finishedPractice([
        'salon-object',
        'salon-product',
        'salon-object-purpose',
      ]),
      isTrue,
    );
    expect(
      find.text('Practice steps finished. You can practise again.'),
      findsOneWidget,
    );
    await tap(tester, 'Back to Home');
    expect(find.text('Practice steps finished'), findsOneWidget);
    await tap(tester, 'My practice');
    expect(
      find.text('1 of 5 days of guided practice finished'),
      findsOneWidget,
    );
  });

  testWidgets('failed attempt save keeps current take and position', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'Open Day 2');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    store.failSave = true;
    await tap(tester, 'Next practice');
    expect(store.progress.promptForDay(2), 0);
    expect(store.progress.attemptedPromptIds, isEmpty);
    expect(find.text('Delete recording'), findsOneWidget);
    store.failSave = false;
    await tap(tester, 'Next practice');
    expect(store.progress.promptForDay(2), 1);
    expect(store.progress.hasAttempted('salon-object'), isTrue);
  });

  testWidgets('switching days clears another day’s recording and transcript', (
    tester,
  ) async {
    await launch(tester, progress: returning, recognition: FakeRecognition());
    await tap(tester, 'Open Day 2');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Hear my words');
    await tester.enterText(find.byType(TextField), 'pilot-access-code');
    await tap(tester, 'Continue');
    expect(find.text('Delete recording'), findsOneWidget);
    final discardsBefore = mic.discards;
    await tap(tester, 'Back to Home');
    await tap(tester, 'Open Day 4');
    expect(find.text('Day 4 • Practice 1 of 3'), findsOneWidget);
    expect(find.text('Delete recording'), findsNothing);
    expect(find.text('WHAT I HEARD'), findsNothing);
    expect(mic.discards, greaterThan(discardsBefore));
  });

  testWidgets('storage failure does not navigate or claim saved state', (
    tester,
  ) async {
    await launch(tester);
    store.failSave = true;
    await tap(tester, 'Get started');
    expect(find.text('Real English.\nReal skills.'), findsOneWidget);
    expect(find.textContaining("couldn't save your place"), findsOneWidget);
    store.failSave = false;
    await tap(tester, 'Get started');
    expect(find.text('What do you study?'), findsOneWidget);
  });

  testWidgets('denied permission and unavailable audio have useful recovery', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'Open Day 1');
    mic.permission = false;
    await tap(tester, 'Enable microphone');
    expect(find.textContaining('Microphone access is off'), findsOneWidget);
    expect(mic.starts, 0);
    speech.unavailable = true;
    await tap(tester, 'Listen to example');
    expect(find.textContaining("Audio isn't available"), findsOneWidget);
    mic.permission = true;
    await tap(tester, 'Check permission again');
    expect(find.text('Start recording'), findsOneWidget);
  });

  testWidgets(
    'returning learner resumes saved phrase without assessment scores',
    (tester) async {
      await launch(tester, progress: returning.copyWith(dayOnePrompt: 2));
      expect(find.text('Ready to speak?'), findsOneWidget);
      await tap(tester, 'Open Day 1');
      expect(find.text('Say why you chose your course.'), findsOneWidget);
    },
  );

  testWidgets('deep linking cannot bypass onboarding', (tester) async {
    await launch(tester);
    container.read(routerProvider).go('/lesson/day-1');
    await tester.pumpAndSettle();
    expect(find.text('Real English.\nReal skills.'), findsOneWidget);
    expect(find.text('Start recording'), findsNothing);
  });

  testWidgets(
    'small display and large text preserve complete journey without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester);
      for (final label in [
        'Get started',
        'Continue',
        'Continue in English',
        'Meet your first lesson',
        'Go to Home',
        'Open Day 1',
        'Enable microphone',
      ]) {
        await tap(tester, label);
        expect(tester.takeException(), isNull);
      }
      await tap(tester, 'Back to Home');
      expect(tester.takeException(), isNull);
      await tap(tester, 'Open Day 5');
      expect(tester.takeException(), isNull);
      await tap(tester, 'Practise in AI Salon');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'visible welcome controls have labels, contrast and touch targets',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await launch(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    },
  );

  testWidgets('practice screen shows saved positions and opens the right day', (
    tester,
  ) async {
    await launch(
      tester,
      progress: const LearnerProgress(
        onboardingStep: 5,
        profession: 'beauty-cosmetology',
        supportLanguage: 'en',
        dayOnePrompt: 1,
        otherDayPrompts: {3: 2},
      ),
    );
    await tap(tester, 'My practice');
    expect(
      find.text(
        'Finished means you recorded every speaking step. It is not a speaking score.',
      ),
      findsOneWidget,
    );
    expect(find.text('Practice 2 of 4'), findsOneWidget);
    expect(find.text('Practice 3 of 3'), findsOneWidget);
    await tap(tester, 'Open Day 3');
    expect(find.text('Day 3 • Practice 3 of 3'), findsOneWidget);
  });

  testWidgets(
    'privacy reset asks first, clears both takes and returns to Welcome',
    (tester) async {
      await launch(
        tester,
        progress: const LearnerProgress(
          onboardingStep: 5,
          profession: 'beauty-cosmetology',
          supportLanguage: 'en',
          dayOnePrompt: 1,
          otherDayPrompts: {3: 2},
          attemptedPromptIds: {'introduce-name', 'customer-greeting'},
          salonRehearsalTurns: {'welcome-needs-consultation': 2},
          salonRecordedSeconds: {'welcome-needs-consultation': 45},
        ),
      );
      await tap(tester, 'Open Day 1');
      await tap(tester, 'Enable microphone');
      await tap(tester, 'Start recording');
      await tap(tester, 'Stop recording');
      await tap(tester, 'Back to Home');
      await tap(tester, 'Privacy and phone data');
      await tap(tester, 'Clear phone data');
      expect(find.text('Clear phone data?'), findsOneWidget);
      await tap(tester, 'Keep my data');
      expect(store.progress.onboarded, isTrue);
      await tap(tester, 'Clear phone data');
      await tester.tap(find.text('Clear phone data').last);
      await tester.pumpAndSettle();
      expect(find.text('Real English.\nReal skills.'), findsOneWidget);
      expect(store.progress.onboarded, isFalse);
      expect(store.progress.promptForDay(1), 0);
      expect(store.progress.promptForDay(3), 0);
      expect(store.progress.attemptedPromptIds, isEmpty);
      expect(store.progress.salonRehearsalTurns, isEmpty);
      expect(store.progress.salonRecordedSeconds, isEmpty);
      expect(mic.discards, greaterThan(0));
    },
  );

  testWidgets('failed local deletion stays on Privacy and offers retry', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    store.failClear = true;
    await tap(tester, 'Privacy and phone data');
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining("couldn't clear your phone data"),
      findsOneWidget,
    );
    expect(store.progress.onboarded, isTrue);
    store.failClear = false;
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(find.text('Real English.\nReal skills.'), findsOneWidget);
  });

  testWidgets('failed audio cleanup keeps saved progress for retry', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    mic.failDiscard = true;
    await tap(tester, 'Privacy and phone data');
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't clear a recording"), findsOneWidget);
    expect(store.progress.onboarded, isTrue);
    mic.failDiscard = false;
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(store.progress.onboarded, isFalse);
  });

  testWidgets('practice and privacy remain usable on a small scaled screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, progress: returning);
    await tap(tester, 'My practice');
    expect(tester.takeException(), isNull);
    await tap(tester, 'Open Day 5');
    expect(tester.takeException(), isNull);
    await tap(tester, 'Back to Home');
    await tap(tester, 'Privacy and phone data');
    expect(tester.takeException(), isNull);
    await tap(tester, 'Clear phone data');
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Words reads a phrase and saves a self-rated review', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'My Words');
    expect(find.text('10 words or phrases to review now'), findsOneWidget);
    expect(find.text('I study Beauty and Cosmetology.'), findsOneWidget);
    await tap(tester, 'Listen and repeat');
    expect(
      speech.spoken.last,
      'Tell someone what you study. I study Beauty and Cosmetology.',
    );
    await tap(tester, 'Felt easy');
    expect(find.text('9 words or phrases to review now'), findsOneWidget);
    expect(store.review['my-course']!.attempts, 1);
    await tap(tester, 'Show all words');
    expect(find.text('I study Beauty and Cosmetology.'), findsOneWidget);
    expect(
      find.text(
        'Your choice sets the next review. It is not a speaking score.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('leaving a phrase stops active audio without a disposed ref', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'My Words');
    speech.speakGate = Completer<void>();
    await tester.tap(find.text('Listen and repeat'));
    await tester.pump();
    await tap(tester, 'Felt easy');
    expect(speech.stops, greaterThan(0));
    expect(tester.takeException(), isNull);
    speech.speakGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('slow replay disables normal playback until it finishes', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'My Words');
    speech.speakGate = Completer<void>();
    await tester.ensureVisible(find.text('Listen slowly'));
    await tester.tap(find.text('Listen slowly'));
    await tester.pump();
    expect(speech.slowFlags.last, isTrue);
    expect(find.text('Stop audio'), findsOneWidget);
    final normalButton = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Listen and repeat'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(normalButton.onPressed, isNull);
    speech.speakGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Listen slowly'), findsOneWidget);
    expect(find.text('Listen and repeat'), findsOneWidget);
  });

  testWidgets('review write failure preserves the phrase and offers retry', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    store.failReviewSave = true;
    await tap(tester, 'My Words');
    await tap(tester, 'More practice');
    expect(find.textContaining("couldn't save that word"), findsOneWidget);
    expect(find.text('10 words or phrases to review now'), findsOneWidget);
    store.failReviewSave = false;
    await tap(tester, 'More practice');
    expect(find.text('9 words or phrases to review now'), findsOneWidget);
  });

  testWidgets('confirmed phone reset also clears word review history', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'My Words');
    await tap(tester, 'Felt easy');
    expect(store.review, isNotEmpty);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'Privacy and phone data');
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(store.review, isEmpty);
    expect(store.progress.onboarded, isFalse);
  });

  testWidgets('My Words fits a small screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, progress: returning);
    await tap(tester, 'My Words');
    expect(tester.takeException(), isNull);
    await tap(tester, 'More practice');
    expect(tester.takeException(), isNull);
    await tap(tester, 'Show all words');
    expect(tester.takeException(), isNull);
  });

  testWidgets('all reviewed words can still be opened from an empty due list', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'My Words');
    for (var i = 0; i < 10; i++) {
      await tap(tester, 'Felt easy');
    }
    expect(find.text('0 words or phrases to review now'), findsOneWidget);
    expect(find.textContaining('All done for now'), findsOneWidget);
    await tap(tester, 'Show all words');
    expect(find.text('I study Beauty and Cosmetology.'), findsOneWidget);
  });

  testWidgets('starting assessment captures all five parts without a score', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'Open starting assessment');
    expect(find.text('Tell us about yourself'), findsOneWidget);
    await tap(tester, 'Hear the task');
    expect(speech.spoken.last, contains('where you are from'));
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Listen to my answer');
    expect(recordingPlayback.paths.last, '/test/recording.m4a');
    await tap(tester, 'Stop my answer');
    expect(recordingPlayback.playing, isFalse);
    await tap(tester, 'Save answer and continue');
    expect(assessmentCapture.captures.keys, contains('baseline-introduction'));
    expect(find.text('Describe the salon picture'), findsOneWidget);
    expect(
      find.text('Generated picture • educator review pending'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'Open starting assessment');
    expect(find.text('Describe the salon picture'), findsOneWidget);
    for (var i = 1; i < 7; i++) {
      await tap(tester, 'Enable microphone');
      await tap(tester, 'Start recording');
      await tap(tester, 'Stop recording');
      await tap(tester, 'Save answer and continue');
    }
    expect(find.text('7 recordings captured'), findsOneWidget);
    expect(
      find.textContaining('No score or assessment result'),
      findsOneWidget,
    );
    expect(assessmentCapture.captures.length, 7);
    expect(baselineMic.starts, 7);
    await tap(tester, 'Hear how to review');
    expect(speech.spoken.last, contains('Tap an answer'));
    await tap(tester, 'Play my answer: Tell us about yourself');
    expect(
      recordingPlayback.paths.last,
      '/test/baseline/baseline-introduction.m4a',
    );
    await tap(tester, 'Go to Home');
    expect(recordingPlayback.playing, isFalse);
    await tap(tester, 'Open starting assessment');
    await tap(tester, 'Play my answer: Tell us about yourself');
    await tap(tester, 'Clear these recordings');
    await tap(tester, 'Clear recordings');
    expect(recordingPlayback.playing, isFalse);
    expect(assessmentCapture.captures, isEmpty);
    expect(find.text('Tell us about yourself'), findsOneWidget);
  });

  testWidgets(
    'starting readiness choice saves offline and clears with phone data',
    (tester) async {
      await launch(tester, progress: returning);
      await tap(tester, 'Open starting assessment');
      for (var i = 0; i < 7; i++) {
        await tap(tester, 'Enable microphone');
        await tap(tester, 'Start recording');
        await tap(tester, 'Stop recording');
        await tap(tester, 'Save answer and continue');
      }
      expect(store.progress.confidenceFor('starting'), isNull);
      await tap(tester, 'Hear the question');
      expect(speech.spoken.last, contains('How ready do you feel'));
      await tap(tester, '3 — Somewhat ready');
      expect(store.progress.confidenceFor('starting')!.rating, 3);
      expect(find.textContaining('Saved on this phone: 3'), findsOneWidget);
      store.failSave = true;
      await tap(tester, '4 — Ready');
      expect(store.progress.confidenceFor('starting')!.rating, 3);
      expect(find.textContaining("couldn't save your place"), findsOneWidget);
      store.failSave = false;
      await tap(tester, '4 — Ready');
      expect(store.progress.confidenceFor('starting')!.rating, 4);
      await tap(tester, 'Go to Home');
      await tap(tester, 'My practice');
      expect(find.text('Starting: 4 — Ready'), findsOneWidget);
      expect(find.text('Day 5: 4 — Ready'), findsNothing);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tap(tester, 'Privacy and phone data');
      await tap(tester, 'Clear phone data');
      await tester.tap(find.text('Clear phone data').last);
      await tester.pumpAndSettle();
      expect(store.progress.confidenceCheckIns, isEmpty);
    },
  );

  testWidgets('Day 5 check-in appears after all speaking steps', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'Open Day 5');
    expect(find.text(confidenceQuestion), findsNothing);
    for (var i = 0; i < 4; i++) {
      await tap(tester, 'Enable microphone');
      await tap(tester, 'Start recording');
      await tap(tester, 'Stop recording');
      await tap(tester, i == 3 ? 'Save this practice' : 'Next practice');
    }
    expect(find.text(confidenceQuestion), findsOneWidget);
    await tap(tester, '5 — Very ready');
    expect(store.progress.confidenceFor('day5')!.rating, 5);
    await tap(tester, 'Back to Home');
    await tap(tester, 'My practice');
    expect(find.text('Day 5: 5 — Very ready'), findsOneWidget);
  });

  testWidgets('Day 5 fixed challenge records, replays and clears offline', (
    tester,
  ) async {
    final day5 = Curriculum.parse(
      File('assets/curriculum/alpha.json').readAsStringSync(),
    ).lessons[4];
    await launch(
      tester,
      progress: returning.copyWith(
        otherDayPrompts: {5: day5.prompts.length - 1},
        attemptedPromptIds: day5.prompts.map((p) => p.id).toSet(),
      ),
    );
    await tap(tester, 'Open Day 5');
    await tap(tester, 'Open Day 5 salon challenge');
    expect(find.text('Understand the customer'), findsOneWidget);
    expect(find.textContaining('No score is given'), findsOneWidget);
    await tap(tester, 'Listen to customer');
    expect(speech.spoken.last, contains('comfortable for work'));
    day5Capture.failSave = true;
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Listen to my answer');
    expect(day5Playback.paths.last, '/test/recording.m4a');
    await tap(tester, 'Stop my answer');
    await tap(tester, 'Save answer and continue');
    expect(find.text('Understand the customer'), findsOneWidget);
    expect(find.textContaining('recording is still here'), findsOneWidget);
    expect(day5Capture.captures, isEmpty);
    day5Capture.failSave = false;
    await tap(tester, 'Save answer and continue');
    for (var i = 1; i < 5; i++) {
      await tap(tester, 'Enable microphone');
      await tap(tester, 'Start recording');
      await tap(tester, 'Stop recording');
      await tap(tester, 'Save answer and continue');
    }
    expect(find.text('5 recordings captured'), findsOneWidget);
    expect(find.textContaining('No score or progress result'), findsOneWidget);
    expect(day5Capture.captures.length, 5);
    expect(assessmentCapture.captures, isEmpty);
    await tap(tester, 'Play my answer: Understand the customer');
    expect(day5Playback.paths.last, '/test/day5/day5-need.m4a');
    await tap(tester, 'Clear these recordings');
    expect(find.text('Clear Day 5 recordings?'), findsOneWidget);
    await tap(tester, 'Clear recordings');
    expect(day5Capture.captures, isEmpty);
    expect(day5Playback.playing, isFalse);
    expect(find.text('Understand the customer'), findsOneWidget);
  });

  testWidgets('Day 5 challenge clear failure preserves phone data for retry', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    day5Capture.failClear = true;
    await tap(tester, 'Privacy and phone data');
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining("couldn't clear the Day-5 challenge"),
      findsOneWidget,
    );
    expect(store.progress.onboarded, isTrue);
    day5Capture.failClear = false;
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(store.progress.onboarded, isFalse);
  });

  testWidgets('Day 5 challenge route waits for completed guided practice', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    container.read(routerProvider).go('/challenge/day-5');
    await tester.pumpAndSettle();
    expect(find.textContaining('Practice 1 of 4'), findsWidgets);
    expect(find.text('Understand the customer'), findsNothing);
  });

  testWidgets('Day 5 challenge works with denied mic and enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final day5 = Curriculum.parse(
      File('assets/curriculum/alpha.json').readAsStringSync(),
    ).lessons[4];
    await launch(
      tester,
      progress: returning.copyWith(
        otherDayPrompts: {5: day5.prompts.length - 1},
        attemptedPromptIds: day5.prompts.map((p) => p.id).toSet(),
      ),
    );
    day5Mic.permission = false;
    await tap(tester, 'Open Day 5');
    await tap(tester, 'Open Day 5 salon challenge');
    await tap(tester, 'Enable microphone');
    expect(find.textContaining('Microphone access is off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confidence choices fit a small screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final day5 = Curriculum.parse(
      File('assets/curriculum/alpha.json').readAsStringSync(),
    ).lessons[4];
    await launch(
      tester,
      progress: returning.copyWith(
        otherDayPrompts: {5: day5.prompts.length - 1},
        attemptedPromptIds: day5.prompts.map((p) => p.id).toSet(),
      ),
    );
    await tap(tester, 'Open Day 5');
    expect(find.text(confidenceQuestion), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tap(tester, '1 — Not ready yet');
    expect(store.progress.confidenceFor('day5')!.rating, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('starting answer playback failure keeps the take for retry', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    await tap(tester, 'Open starting assessment');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    recordingPlayback.failPlay = true;
    await tap(tester, 'Listen to my answer');
    expect(find.textContaining("couldn't play that answer"), findsOneWidget);
    expect(assessmentCapture.captures, isEmpty);
    recordingPlayback.failPlay = false;
    await tap(tester, 'Listen to my answer');
    expect(recordingPlayback.playing, isTrue);
    await tap(tester, 'Save answer and continue');
    expect(recordingPlayback.playing, isFalse);
    expect(assessmentCapture.captures.length, 1);
  });

  testWidgets('failed baseline save preserves the take and privacy clears it', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    assessmentCapture.failSave = true;
    await tap(tester, 'Open starting assessment');
    await tap(tester, 'Enable microphone');
    await tap(tester, 'Start recording');
    await tap(tester, 'Stop recording');
    await tap(tester, 'Save answer and continue');
    expect(find.text('Tell us about yourself'), findsOneWidget);
    expect(find.textContaining('recording is still here'), findsOneWidget);
    assessmentCapture.failSave = false;
    await tap(tester, 'Save answer and continue');
    expect(assessmentCapture.captures.length, 1);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tap(tester, 'Privacy and phone data');
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(assessmentCapture.captures, isEmpty);
    expect(store.progress.onboarded, isFalse);
  });

  testWidgets('baseline cache deletion failure keeps Privacy open for retry', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    assessmentCapture.failClear = true;
    await tap(tester, 'Privacy and phone data');
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining("couldn't clear the starting recordings"),
      findsOneWidget,
    );
    expect(store.progress.onboarded, isTrue);
    assessmentCapture.failClear = false;
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(store.progress.onboarded, isFalse);
  });

  testWidgets('phone data stays intact if answer playback cannot stop', (
    tester,
  ) async {
    await launch(tester, progress: returning);
    recordingPlayback.failStop = true;
    await tap(tester, 'Privacy and phone data');
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't stop an answer"), findsOneWidget);
    expect(store.progress.onboarded, isTrue);
    recordingPlayback.failStop = false;
    await tap(tester, 'Clear phone data');
    await tester.tap(find.text('Clear phone data').last);
    await tester.pumpAndSettle();
    expect(store.progress.onboarded, isFalse);
  });

  testWidgets('baseline permission, missing voice and large text are usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, progress: returning);
    baselineMic.permission = false;
    speech.unavailable = true;
    await tap(tester, 'Open starting assessment');
    await tap(tester, 'Hear the task');
    expect(find.textContaining("Audio isn't available"), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tap(tester, 'Enable microphone');
    expect(find.textContaining('Microphone access is off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
