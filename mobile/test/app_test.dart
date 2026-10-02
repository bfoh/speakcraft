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

import 'support/fakes.dart';

void main() {
  late MemoryProgressStore store;
  late FakeMicrophone mic;
  late FakeSpeech speech;
  late ProviderContainer container;

  Future<void> launch(
    WidgetTester tester, {
    LearnerProgress progress = const LearnerProgress(),
    SpeechRecognition recognition = const UnconfiguredSpeechRecognition(),
    SpeakingFeedback feedback = const UnconfiguredSpeakingFeedback(),
    KoraConversation conversation = const UnconfiguredKoraConversation(),
    KoraConversation salon = const UnconfiguredKoraConversation(),
    ExpressionGenerator expression = const UnconfiguredExpressionGenerator(),
  }) async {
    store = MemoryProgressStore()..progress = progress;
    mic = FakeMicrophone();
    speech = FakeSpeech();
    container = ProviderContainer(
      overrides: [
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
      expect(find.textContaining('No assessment result'), findsOneWidget);
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
      find.text('This shows where to continue. It is not a speaking score.'),
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
}
