import '../../../core/auth/app_user.dart';
import '../../../core/database/server_database.dart';
import '../dto/save_quiz_request.dart';
import '../models/quiz.dart';

class QuizRepository {
  const QuizRepository(this._database);

  final ServerDatabase _database;

  List<Quiz> findVisibleFor(AppUser user, {String? status}) {
    final conditions = <String>['is_deleted = 0'];
    final parameters = <Object?>[];

    if (user.isStudent) {
      conditions.add("status = 'published'");
    } else if (user.isTeacher) {
      conditions.add('teacher_id = ?');
      parameters.add(user.id);
    }
    if (status != null && !user.isStudent) {
      conditions.add('status = ?');
      parameters.add(status);
    }

    final rows = _database.connection.select(
      'SELECT * FROM quizzes WHERE ${conditions.join(' AND ')} '
      'ORDER BY updated_at DESC',
      parameters,
    );
    return rows.map(Quiz.fromRow).toList(growable: false);
  }

  Quiz? findById(int quizId) {
    final rows = _database.connection.select(
      'SELECT * FROM quizzes WHERE quiz_id = ? AND is_deleted = 0',
      [quizId],
    );
    return rows.isEmpty ? null : Quiz.fromRow(rows.single);
  }

  Quiz create(int teacherId, SaveQuizRequest request) {
    final db = _database.connection;
    final now = DateTime.now().millisecondsSinceEpoch;
    db.execute(
      '''
      INSERT INTO quizzes (
        teacher_id, title, description, time_limit_sec, question_count,
        shuffle_order, status, is_deleted, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)
      ''',
      [
        teacherId,
        request.title,
        request.description,
        request.timeLimitSeconds,
        request.questionCount,
        request.shuffleOrder ? 1 : 0,
        request.status,
        now,
        now,
      ],
    );
    return findById(db.lastInsertRowId)!;
  }

  Quiz update(int quizId, SaveQuizRequest request) {
    final db = _database.connection;
    db.execute(
      '''
      UPDATE quizzes
      SET title = ?, description = ?, time_limit_sec = ?, question_count = ?,
          shuffle_order = ?, status = ?, updated_at = ?
      WHERE quiz_id = ? AND is_deleted = 0
      ''',
      [
        request.title,
        request.description,
        request.timeLimitSeconds,
        request.questionCount,
        request.shuffleOrder ? 1 : 0,
        request.status,
        DateTime.now().millisecondsSinceEpoch,
        quizId,
      ],
    );
    return findById(quizId)!;
  }

  void softDelete(int quizId) {
    _database.connection.execute(
      'UPDATE quizzes SET is_deleted = 1, updated_at = ? WHERE quiz_id = ?',
      [DateTime.now().millisecondsSinceEpoch, quizId],
    );
  }
}
