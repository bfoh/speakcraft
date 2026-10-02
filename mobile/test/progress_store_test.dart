import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:speakcraft/core/storage/progress_store.dart';
import 'package:speakcraft/core/storage/review_store.dart';
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
            otherDayPrompts: {2: 1, 3: 2, 5: 3},
            attemptedPromptIds: {'introduce-name', 'customer-greeting'},
          ),
        );
        await store.saveReview(
          'my-course',
          ReviewProgress(
            attempts: 1,
            easeStage: 1,
            lastReviewedAt: DateTime.utc(2026, 10, 2),
            nextReviewAt: DateTime.utc(2026, 10, 3),
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
        expect(restored.promptForDay(2), 1);
        expect(restored.promptForDay(3), 2);
        expect(restored.promptForDay(4), 0);
        expect(restored.promptForDay(5), 3);
        expect(restored.hasAttempted('introduce-name'), isTrue);
        expect(restored.hasAttempted('customer-greeting'), isTrue);
        expect(restored.hasAttempted('introduce-study'), isFalse);
        expect((await store.loadReview())['my-course']!.easeStage, 1);
      } finally {
        await store.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'version 3 database gains attempt markers without inferring them',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp('speakcraft-v3-');
      final path = '${directory.path}/progress.db';
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE learner_progress (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              onboarding_step INTEGER NOT NULL,
              profession TEXT,
              support_language TEXT,
              day_one_prompt INTEGER NOT NULL
            )
          ''');
            await db.execute('''
            CREATE TABLE lesson_positions (
              day INTEGER PRIMARY KEY,
              prompt_index INTEGER NOT NULL
            )
          ''');
            await db.execute('''
            CREATE TABLE review_state (
              item_id TEXT PRIMARY KEY,
              attempts INTEGER NOT NULL,
              ease_stage INTEGER NOT NULL,
              last_reviewed_at INTEGER NOT NULL,
              next_review_at INTEGER NOT NULL
            )
          ''');
          },
        ),
      );
      await old.insert('learner_progress', {
        'id': 1,
        'onboarding_step': 5,
        'profession': 'beauty-cosmetology',
        'support_language': 'en',
        'day_one_prompt': 3,
      });
      await old.insert('lesson_positions', {'day': 3, 'prompt_index': 2});
      await old.close();
      final upgraded = await SqliteProgressStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final progress = await upgraded.load();
        expect(progress.promptForDay(1), 3);
        expect(progress.promptForDay(3), 2);
        expect(progress.attemptedPromptIds, isEmpty);
        await upgraded.save(progress.withAttemptedPrompt('customer-greeting'));
        expect(
          (await upgraded.load()).hasAttempted('customer-greeting'),
          isTrue,
        );
      } finally {
        await upgraded.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('practice finishes only after all authored prompts have attempts', () {
    const ids = ['one', 'two', 'three'];
    var progress = const LearnerProgress();
    expect(progress.finishedPractice(ids), isFalse);
    progress = progress.withAttemptedPrompt('one');
    expect(progress.attemptedCount(ids), 1);
    expect(progress.finishedPractice(ids), isFalse);
    progress = progress.withAttemptedPrompt('two').withAttemptedPrompt('three');
    expect(progress.finishedPractice(ids), isTrue);
    expect(progress.finishedPractice([...ids, 'new-prompt']), isFalse);
  });

  test('version 1 database upgrades without losing Day-1 position', () async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('speakcraft-v1-');
    final path = '${directory.path}/progress.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE learner_progress (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              onboarding_step INTEGER NOT NULL CHECK (onboarding_step BETWEEN 0 AND 5),
              profession TEXT,
              support_language TEXT,
              day_one_prompt INTEGER NOT NULL CHECK (day_one_prompt >= 0)
            )
          ''');
        },
      ),
    );
    await old.insert('learner_progress', {
      'id': 1,
      'onboarding_step': 5,
      'profession': 'beauty-cosmetology',
      'support_language': 'en',
      'day_one_prompt': 3,
    });
    await old.close();
    final upgraded = await SqliteProgressStore.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final progress = await upgraded.load();
      expect(progress.dayOnePrompt, 3);
      expect(progress.promptForDay(2), 0);
      expect(await upgraded.loadReview(), isEmpty);
      await upgraded.save(progress.withPromptForDay(2, 1));
      expect((await upgraded.load()).promptForDay(2), 1);
    } finally {
      await upgraded.close();
      await directory.delete(recursive: true);
    }
  });

  test(
    'version 2 database gains review table without losing daily place',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp('speakcraft-v2-');
      final path = '${directory.path}/progress.db';
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE learner_progress (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              onboarding_step INTEGER NOT NULL CHECK (onboarding_step BETWEEN 0 AND 5),
              profession TEXT,
              support_language TEXT,
              day_one_prompt INTEGER NOT NULL CHECK (day_one_prompt >= 0)
            )
          ''');
            await db.execute('''
            CREATE TABLE lesson_positions (
              day INTEGER PRIMARY KEY CHECK (day BETWEEN 2 AND 5),
              prompt_index INTEGER NOT NULL CHECK (prompt_index >= 0)
            )
          ''');
          },
        ),
      );
      await old.insert('learner_progress', {
        'id': 1,
        'onboarding_step': 5,
        'profession': 'beauty-cosmetology',
        'support_language': 'en',
        'day_one_prompt': 1,
      });
      await old.insert('lesson_positions', {'day': 3, 'prompt_index': 2});
      await old.close();
      final upgraded = await SqliteProgressStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        expect((await upgraded.load()).promptForDay(3), 2);
        expect(await upgraded.loadReview(), isEmpty);
        await upgraded.saveReview(
          'welcome',
          ReviewProgress(
            attempts: 1,
            easeStage: 1,
            lastReviewedAt: DateTime.utc(2026, 10, 2),
            nextReviewAt: DateTime.utc(2026, 10, 3),
          ),
        );
        expect((await upgraded.loadReview())['welcome']!.attempts, 1);
      } finally {
        await upgraded.close();
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
    'SQLite clear removes onboarding and all daily positions on reopen',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'speakcraft-clear-',
      );
      final path = '${directory.path}/progress.db';
      var store = await SqliteProgressStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        await store.save(
          const LearnerProgress(
            onboardingStep: 5,
            profession: 'beauty-cosmetology',
            supportLanguage: 'en',
            dayOnePrompt: 2,
            otherDayPrompts: {2: 1, 3: 2, 4: 1, 5: 3},
            attemptedPromptIds: {'introduce-name', 'customer-greeting'},
          ),
        );
        await store.saveReview(
          'my-course',
          ReviewProgress(
            attempts: 2,
            easeStage: 0,
            lastReviewedAt: DateTime.utc(2026, 10, 2),
            nextReviewAt: DateTime.utc(2026, 10, 2, 4),
          ),
        );
        await store.clear();
        await store.close();
        store = await SqliteProgressStore.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final progress = await store.load();
        expect(progress.onboarded, isFalse);
        expect(progress.profession, isNull);
        expect(progress.supportLanguage, isNull);
        for (var day = 1; day <= 5; day++) {
          expect(progress.promptForDay(day), 0);
        }
        expect(await store.database.query('learner_progress'), isEmpty);
        expect(await store.database.query('lesson_positions'), isEmpty);
        expect(await store.database.query('review_state'), isEmpty);
        expect(await store.database.query('practice_attempts'), isEmpty);
      } finally {
        await store.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('failed clear keeps published position and allows retry', () async {
    const saved = LearnerProgress(
      onboardingStep: 5,
      dayOnePrompt: 2,
      otherDayPrompts: {3: 1},
    );
    final store = MemoryProgressStore()
      ..progress = saved
      ..failClear = true;
    final controller = SessionController(store, saved);
    addTearDown(controller.dispose);
    expect(await controller.reset(), isFalse);
    expect(controller.progress.promptForDay(3), 1);
    expect(store.progress.onboarded, isTrue);
    expect(controller.error, contains('couldn\'t clear'));
    store.failClear = false;
    expect(await controller.reset(), isTrue);
    expect(controller.progress.onboarded, isFalse);
    expect(store.progress.promptForDay(3), 0);
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
