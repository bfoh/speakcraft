import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:speakcraft/core/storage/progress_store.dart';
import 'package:speakcraft/core/storage/sqlite_progress_store.dart';

import 'support/fakes.dart';

void main() {
  test(
    'SQLite persists onboarding and position across a real reopen',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'speakcraft-test-',
      );
      final path = '${directory.path}/progress.db';
      var store = await SqliteProgressStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        expect((await store.load()).onboarded, isFalse);
        await store.save(
          const LearnerProgress(
            onboardingStep: 5,
            profession: 'beauty-cosmetology',
            supportLanguage: 'en',
            dayOnePrompt: 2,
          ),
        );
        await store.close();
        store = await SqliteProgressStore.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = await store.load();
        expect(restored.onboarded, isTrue);
        expect(restored.profession, 'beauty-cosmetology');
        expect(restored.supportLanguage, 'en');
        expect(restored.dayOnePrompt, 2);
      } finally {
        await store.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('save failure preserves previous state and permits retry', () async {
    final store = MemoryProgressStore()..failSave = true;
    final controller = SessionController(store, const LearnerProgress());
    addTearDown(controller.dispose);
    expect(
      await controller.update(const LearnerProgress(onboardingStep: 1)),
      isFalse,
    );
    expect(controller.progress.onboardingStep, 0);
    expect(controller.error, isNotNull);
    store.failSave = false;
    expect(
      await controller.update(const LearnerProgress(onboardingStep: 1)),
      isTrue,
    );
    expect(controller.progress.onboardingStep, 1);
    expect(controller.error, isNull);
  });

  test(
    'state is only confirmed after save and competing writes are rejected',
    () async {
      final store = MemoryProgressStore()..saveGate = Completer<void>();
      final controller = SessionController(store, const LearnerProgress());
      addTearDown(controller.dispose);
      final pending = controller.update(
        const LearnerProgress(onboardingStep: 1),
      );
      expect(controller.saving, isTrue);
      expect(controller.progress.onboardingStep, 0);
      expect(
        await controller.update(const LearnerProgress(onboardingStep: 2)),
        isFalse,
      );
      store.saveGate!.complete();
      expect(await pending, isTrue);
      expect(controller.progress.onboardingStep, 1);
    },
  );
}
