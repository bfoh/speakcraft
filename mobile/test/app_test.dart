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
            progress: progress,
            microphone: mic,
            conversationMicrophone: FakeMicrophone(),
            speech: speech,
            recognition: recognition,
            feedback: feedback,
            conversation: conversation,
            salon: salon,
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
}
