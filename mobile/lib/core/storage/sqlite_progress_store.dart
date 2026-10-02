import 'package:sqflite/sqflite.dart';

import 'progress_store.dart';

class SqliteProgressStore implements ProgressStore {
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
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE lesson_positions (
                day INTEGER PRIMARY KEY CHECK (day BETWEEN 2 AND 5),
                prompt_index INTEGER NOT NULL CHECK (prompt_index >= 0)
              )
            ''');
          }
        },
      ),
    );
    return SqliteProgressStore(db);
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
    return LearnerProgress(
      onboardingStep: row['onboarding_step'] as int,
      profession: row['profession'] as String?,
      supportLanguage: row['support_language'] as String?,
      dayOnePrompt: row['day_one_prompt'] as int,
      otherDayPrompts: Map.unmodifiable({
        for (final position in positions)
          position['day'] as int: position['prompt_index'] as int,
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
    });
  }

  @override
  Future<void> close() => database.close();
}
