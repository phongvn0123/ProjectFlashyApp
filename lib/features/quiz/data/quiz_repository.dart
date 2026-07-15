import 'package:sqflite/sqflite.dart';

import '../../../services/api_service.dart';
import '../../../services/local_db_service.dart';
import 'quiz_model.dart';

/// Tầng data của feature Quiz.
///
/// Repository chịu trách nhiệm đọc/ghi nguồn dữ liệu và trả về model Dart.
/// Khi có REST API thật, có thể bổ sung [ApiService] tại đây mà không sửa UI.
class QuizRepository {
  const QuizRepository(this._localDb, this._api);

  final LocalDbService _localDb;
  final ApiService _api;

  Future<List<QuizModel>> findAll({String? status}) async {
    try {
      final remote = await _findAllFromApi(status: status);
      await _cache(remote);
      return remote;
    } catch (_) {
      return _findAllFromLocal(status: status);
    }
  }

  Future<List<QuizModel>> _findAllFromApi({String? status}) async {
    final response = await _api.get(
      'quizzes/',
      query: status == null ? null : {'status': status},
    );
    if (response is! Map || response['data'] is! List) {
      throw const FormatException('API Quiz trả dữ liệu không hợp lệ.');
    }

    return (response['data'] as List)
        .map(
          (item) => QuizModel.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<List<QuizModel>> _findAllFromLocal({String? status}) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'quizzes',
      where: status == null
          ? 'is_deleted = ?'
          : 'is_deleted = ? AND status = ?',
      whereArgs: status == null ? const [0] : [0, status],
      orderBy: 'updated_at DESC',
    );

    return rows.map(QuizModel.fromDatabase).toList(growable: false);
  }

  Future<QuizModel?> findById(int quizId) async {
    try {
      final response = await _api.get('quizzes/$quizId');
      if (response is! Map || response['data'] is! Map) {
        throw const FormatException('API Quiz trả dữ liệu không hợp lệ.');
      }
      return QuizModel.fromJson(
        (response['data'] as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return _findByIdFromLocal(quizId);
    }
  }

  Future<QuizModel?> _findByIdFromLocal(int quizId) async {
    final db = await _localDb.database;
    final rows = await db.query(
      'quizzes',
      where: 'quiz_id = ? AND is_deleted = ?',
      whereArgs: [quizId, 0],
      limit: 1,
    );

    return rows.isEmpty ? null : QuizModel.fromDatabase(rows.single);
  }

  Future<void> _cache(List<QuizModel> quizzes) async {
    final db = await _localDb.database;
    await db.transaction((transaction) async {
      for (final quiz in quizzes) {
        await transaction.insert(
          'quizzes',
          quiz.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
