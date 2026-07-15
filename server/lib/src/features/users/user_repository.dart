import '../../core/auth/app_user.dart';
import '../../core/auth/firebase_identity.dart';
import '../../core/database/server_database.dart';

class UserRepository {
  const UserRepository(this._database);

  final ServerDatabase _database;

  AppUser findOrCreate(FirebaseIdentity identity) {
    final db = _database.connection;
    final existing = db.select('SELECT * FROM users WHERE firebase_uid = ?', [
      identity.uid,
    ]);
    if (existing.isNotEmpty) {
      return AppUser.fromRow(existing.single);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    db.execute(
      '''
      INSERT INTO users (
        firebase_uid, email, role, status, created_at, updated_at
      ) VALUES (?, ?, 'student', 'active', ?, ?)
      ''',
      [identity.uid, identity.email, now, now],
    );

    return AppUser.fromRow(
      db.select('SELECT * FROM users WHERE firebase_uid = ?', [
        identity.uid,
      ]).single,
    );
  }
}
