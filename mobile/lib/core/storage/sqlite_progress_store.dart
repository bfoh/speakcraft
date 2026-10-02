import 'package:sqflite/sqflite.dart';

import 'progress_store.dart';
import 'review_store.dart';

class SqliteProgressStore implements ProgressStore, ReviewStore {
  SqliteProgressStore(this.database);
  final Database database;

  static Future<SqliteProgressStore> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final db = await dbFactory.openDatabase(
      path ?? '${await getDatabasesPath()}/speakcraft.db',
      options: OpenDatabaseOptions(
        version: 6,
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
          await _createReviewTable(db);
          await _createPracticeAttemptsTable(db);
          await _createSalonRehearsalsTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE lesson_positions (
                day INTEGER PRIMARY KEY CHECK (day BETWEEN 2 AND 5),
                prompt_index INTEGER NOT NULL CHECK (prompt_index >= 0)
              )
            ''');
          }
          if (oldVersion < 3) await _createReviewTable(db);
          if (oldVersion < 4) await _createPracticeAttemptsTable(db);
          if (oldVersion < 5) {
            await _createSalonRehearsalsTable(db);
          } else if (oldVersion < 6) {
            await db.execute('''
              ALTER TABLE salon_rehearsals
              ADD COLUMN longest_recorded_seconds INTEGER NOT NULL DEFAULT 0
                CHECK (longest_recorded_seconds BETWEEN 0 AND 360)
            ''');
          }
        },
      ),
    );
    return SqliteProgressStore(db);
  }

  static Future<void> _createReviewTable(DatabaseExecutor db) => db.execute('''
    CREATE TABLE review_state (
      item_id TEXT PRIMARY KEY,
      attempts INTEGER NOT NULL CHECK (attempts >= 1),
      ease_stage INTEGER NOT NULL CHECK (ease_stage BETWEEN 0 AND 3),
      last_reviewed_at INTEGER NOT NULL,
      next_review_at INTEGER NOT NULL
    )
  ''');

  static Future<void> _createPracticeAttemptsTable(DatabaseExecutor db) =>
      db.execute('''
    CREATE TABLE practice_attempts (
      prompt_id TEXT PRIMARY KEY NOT NULL CHECK (length(prompt_id) BETWEEN 1 AND 80)
    )
  ''');

  static Future<void> _createSalonRehearsalsTable(DatabaseExecutor db) =>
      db.execute('''
    CREATE TABLE salon_rehearsals (
      scenario_id TEXT PRIMARY KEY NOT NULL CHECK (length(scenario_id) BETWEEN 1 AND 80),
      best_turns INTEGER NOT NULL CHECK (best_turns BETWEEN 1 AND 6),
      longest_recorded_seconds INTEGER NOT NULL DEFAULT 0
        CHECK (longest_recorded_seconds BETWEEN 0 AND 360)
    )
  ''');

  @override
  Future<Map<String, ReviewProgress>> loadReview() async {
    final rows = await database.query('review_state');
    return Map.unmodifiable({
      for (final row in rows)
        row['item_id'] as String: ReviewProgress(
          attempts: row['attempts'] as int,
          easeStage: row['ease_stage'] as int,
          lastReviewedAt: DateTime.fromMillisecondsSinceEpoch(
            row['last_reviewed_at'] as int,
            isUtc: true,
          ),
          nextReviewAt: DateTime.fromMillisecondsSinceEpoch(
            row['next_review_at'] as int,
            isUtc: true,
          ),
        ),
    });
  }

  @override
  Future<void> saveReview(String itemId, ReviewProgress progress) async {
    await database.insert('review_state', {
      'item_id': itemId,
      'attempts': progress.attempts,
      'ease_stage': progress.easeStage,
      'last_reviewed_at': progress.lastReviewedAt.millisecondsSinceEpoch,
      'next_review_at': progress.nextReviewAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<LearnerProgress> load() async {
    final rows = await database.query(
      'learner_progress',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (rows.isEmpty) return const LearnerProgress();
    final row = rows.single;
    final positions = await database.query('lesson_positions');
    final attempts = await database.query('practice_attempts');
    final rehearsals = await database.query('salon_rehearsals');
    return LearnerProgress(
      onboardingStep: row['onboarding_step'] as int,
      profession: row['profession'] as String?,
      supportLanguage: row['support_language'] as String?,
      dayOnePrompt: row['day_one_prompt'] as int,
      otherDayPrompts: Map.unmodifiable({
        for (final position in positions)
          position['day'] as int: position['prompt_index'] as int,
      }),
      attemptedPromptIds: Set.unmodifiable({
        for (final attempt in attempts) attempt['prompt_id'] as String,
      }),
      salonRehearsalTurns: Map.unmodifiable({
        for (final rehearsal in rehearsals)
          rehearsal['scenario_id'] as String: rehearsal['best_turns'] as int,
      }),
      salonRecordedSeconds: Map.unmodifiable({
        for (final rehearsal in rehearsals)
          rehearsal['scenario_id'] as String:
              rehearsal['longest_recorded_seconds'] as int,
      }),
    );
  }

  @override
  Future<void> save(LearnerProgress progress) async {
    await database.transaction((txn) async {
      await txn.insert('learner_progress', {
        'id': 1,
        'onboarding_step': progress.onboardingStep,
        'profession': progress.profession,
        'support_language': progress.supportLanguage,
        'day_one_prompt': progress.dayOnePrompt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var day = 2; day <= 5; day++) {
        await txn.insert('lesson_positions', {
          'day': day,
          'prompt_index': progress.promptForDay(day),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await txn.delete('practice_attempts');
      for (final promptId in progress.attemptedPromptIds) {
        await txn.insert('practice_attempts', {'prompt_id': promptId});
      }
      await txn.delete('salon_rehearsals');
      for (final entry in progress.salonRehearsalTurns.entries) {
        await txn.insert('salon_rehearsals', {
          'scenario_id': entry.key,
          'best_turns': entry.value,
          'longest_recorded_seconds': progress.longestSalonRecordedSeconds(
            entry.key,
          ),
        });
      }
    });
  }

  @override
  Future<void> clear() async {
    await database.transaction((txn) async {
      await txn.delete('review_state');
      await txn.delete('practice_attempts');
      await txn.delete('salon_rehearsals');
      await txn.delete('lesson_positions');
      await txn.delete('learner_progress');
    });
  }

  @override
  Future<void> close() => database.close();
}
