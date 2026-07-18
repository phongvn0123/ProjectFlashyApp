import 'package:sqflite/sqflite.dart';

/// Proves plain `sqflite` (no FFI, no `databaseFactory` override) can open a
/// database in Android app-private storage, insert a row, and read it back.
///
/// See 00-RESEARCH.md Pattern 3 (Plain sqflite Round-Trip) and Pitfall 6
/// (never reintroduce the FFI factory override that Windows support used to
/// require — this project is Android-only now).
Future<String> testSqliteInsertAndRead() async {
  try {
    final databasesPath = await getDatabasesPath();
    final dbPath = '$databasesPath/spike.db';

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE spike_test (id INTEGER PRIMARY KEY, value TEXT)',
        );
      },
    );

    await db.insert('spike_test', {'value': 'hello-from-android'});

    final rows = await db.query('spike_test');
    await db.close();

    return 'SQLITE PASS: ' '${rows.first}';
  } catch (e) {
    return 'SQLITE FAIL: ' '$e';
  }
}
