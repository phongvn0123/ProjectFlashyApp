import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

class DatabaseService {
  const DatabaseService._();

  static const databaseName = 'memocard.db';

  static Future<Database> open() async {
    final path = p.join(await getDatabasesPath(), databaseName);
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        for (final statement in kAllTableCreateStatements) {
          await db.execute(statement);
        }
      },
      // Future schema changes should bump version and add onUpgrade.
      // Squash migrations weekly to keep fresh setup under 500ms.
    );
  }
}
