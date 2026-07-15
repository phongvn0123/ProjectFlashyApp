import '../../../core/auth/app_user.dart';
import '../../../core/errors/api_exception.dart';
import '../data/quiz_repository.dart';
import '../dto/save_quiz_request.dart';
import '../models/quiz.dart';

class QuizService {
  const QuizService(this._repository);

  final QuizRepository _repository;

  List<Quiz> list(AppUser user, {String? status}) {
    if (status != null && !{'draft', 'published', 'closed'}.contains(status)) {
      throw ApiException.badRequest('Trạng thái Quiz/Test không hợp lệ.');
    }
    return _repository.findVisibleFor(user, status: status);
  }

  Quiz detail(AppUser user, int quizId) {
    final quiz = _requireQuiz(quizId);
    if (user.isStudent && quiz.status != 'published') {
      throw ApiException.forbidden();
    }
    if (user.isTeacher && quiz.teacherId != user.id) {
      throw ApiException.forbidden('Bạn không sở hữu Quiz/Test này.');
    }
    return quiz;
  }

  Quiz create(AppUser user, SaveQuizRequest request) {
    _requireTeacherOrAdmin(user);
    return _repository.create(user.id, request);
  }

  Quiz update(AppUser user, int quizId, SaveQuizRequest request) {
    final quiz = _requireQuiz(quizId);
    _requireOwnerOrAdmin(user, quiz);
    return _repository.update(quizId, request);
  }

  void delete(AppUser user, int quizId) {
    final quiz = _requireQuiz(quizId);
    _requireOwnerOrAdmin(user, quiz);
    _repository.softDelete(quizId);
  }

  Quiz _requireQuiz(int quizId) {
    if (quizId <= 0) {
      throw ApiException.badRequest('Quiz ID không hợp lệ.');
    }
    return _repository.findById(quizId) ??
        (throw ApiException.notFound('Không tìm thấy Quiz/Test.'));
  }

  void _requireTeacherOrAdmin(AppUser user) {
    if (!user.isTeacher && !user.isAdmin) {
      throw ApiException.forbidden(
        'Chỉ Teacher hoặc Admin được tạo Quiz/Test.',
      );
    }
  }

  void _requireOwnerOrAdmin(AppUser user, Quiz quiz) {
    if (!user.isAdmin && (!user.isTeacher || quiz.teacherId != user.id)) {
      throw ApiException.forbidden('Bạn không sở hữu Quiz/Test này.');
    }
  }
}
