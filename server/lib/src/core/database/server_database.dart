import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// Kết nối SQLite thuộc Dart server, tách biệt với SQLite trên điện thoại.
class ServerDatabase {
  ServerDatabase._(this.connection);

  final Database connection;

  static ServerDatabase open({
    required String databasePath,
    required String migrationDirectory,
  }) {
    final file = File(databasePath);
    file.parent.createSync(recursive: true);

    final database = sqlite3.open(file.path);
    _runMigrations(database, Directory(migrationDirectory));
    return ServerDatabase._(database);
  }

  static void _runMigrations(Database database, Directory directory) {
    if (!directory.existsSync()) {
      throw StateError('Migration directory not found: ${directory.path}');
    }

    database.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        migration_name TEXT PRIMARY KEY,
        applied_at INTEGER NOT NULL
      )
    ''');

    final migrationFiles =
        directory
            .listSync()
            .whereType<File>()
            .where(
              (file) => RegExp(r'\d+_.+\.sql$').hasMatch(_fileName(file.path)),
            )
            .toList()
          ..sort((a, b) => _fileName(a.path).compareTo(_fileName(b.path)));

    for (final file in migrationFiles) {
      final name = _fileName(file.path);
      final applied = database.select(
        'SELECT 1 FROM schema_migrations WHERE migration_name = ?',
        [name],
      );
      if (applied.isNotEmpty) continue;

      database.execute('BEGIN');
      try {
        database.execute(file.readAsStringSync());
        database.execute(
          'INSERT INTO schema_migrations (migration_name, applied_at) '
          'VALUES (?, ?)',
          [name, DateTime.now().millisecondsSinceEpoch],
        );
        database.execute('COMMIT');
      } catch (_) {
        database.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  static String _fileName(String path) =>
      path.replaceAll('\\', '/').split('/').last;

  static ServerDatabase inMemory({required String schema}) {
    final database = sqlite3.openInMemory()..execute(schema);
    return ServerDatabase._(database);
  }

  void close() => connection.close();
}
