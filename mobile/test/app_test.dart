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
            speech: speech,
            recognition: recognition,
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
