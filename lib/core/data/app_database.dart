import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), 'memocard.db');
    _database = await openDatabase(
      path,
      version: 4,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    return _database!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        full_name TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE flashcard_sets (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        visibility TEXT NOT NULL,
        card_count INTEGER NOT NULL DEFAULT 0,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        set_id TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE learning_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        set_id TEXT NOT NULL,
        known_count INTEGER NOT NULL,
        unknown_count INTEGER NOT NULL,
        status TEXT NOT NULL,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE classrooms (
        id TEXT PRIMARY KEY,
        teacher_id TEXT NOT NULL,
        name TEXT NOT NULL,
        join_code TEXT NOT NULL UNIQUE,
        is_join_enabled INTEGER NOT NULL,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE class_members (
        class_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT,
        PRIMARY KEY(class_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        teacher_id TEXT NOT NULL,
        set_id TEXT NOT NULL,
        title TEXT NOT NULL,
        question_count INTEGER NOT NULL,
        status TEXT NOT NULL,
        time_limit_minutes INTEGER NOT NULL DEFAULT 15,
        question_order TEXT NOT NULL DEFAULT 'sequential',
        answer_order TEXT NOT NULL DEFAULT 'fixed',
        assigned_class_id TEXT,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE quiz_questions_demo (
        id TEXT PRIMARY KEY,
        quiz_id TEXT NOT NULL,
        prompt TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        set_id TEXT NOT NULL,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        server_id TEXT,
        dirty_at TEXT,
        synced_at TEXT
      )
    ''');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quizzes (
          id TEXT PRIMARY KEY,
          teacher_id TEXT NOT NULL,
          set_id TEXT NOT NULL,
          title TEXT NOT NULL,
          question_count INTEGER NOT NULL,
          status TEXT NOT NULL,
          time_limit_minutes INTEGER NOT NULL DEFAULT 15,
          question_order TEXT NOT NULL DEFAULT 'sequential',
          answer_order TEXT NOT NULL DEFAULT 'fixed',
          assigned_class_id TEXT,
          server_id TEXT,
          dirty_at TEXT,
          synced_at TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      final columns = await db.rawQuery('PRAGMA table_info(quizzes)');
      final hasAssignedClassId = columns.any(
        (column) => column['name'] == 'assigned_class_id',
      );
      if (!hasAssignedClassId) {
        await db.execute(
          'ALTER TABLE quizzes ADD COLUMN assigned_class_id TEXT',
        );
      }
    }
    if (oldVersion < 4) {
      await _addColumnIfMissing(
        db,
        'quizzes',
        'time_limit_minutes',
        "INTEGER NOT NULL DEFAULT 15",
      );
      await _addColumnIfMissing(
        db,
        'quizzes',
        'question_order',
        "TEXT NOT NULL DEFAULT 'sequential'",
      );
      await _addColumnIfMissing(
        db,
        'quizzes',
        'answer_order',
        "TEXT NOT NULL DEFAULT 'fixed'",
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_questions_demo (
          id TEXT PRIMARY KEY,
          quiz_id TEXT NOT NULL,
          prompt TEXT NOT NULL,
          correct_answer TEXT NOT NULL,
          order_index INTEGER NOT NULL,
          server_id TEXT,
          dirty_at TEXT,
          synced_at TEXT
        )
      ''');
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
