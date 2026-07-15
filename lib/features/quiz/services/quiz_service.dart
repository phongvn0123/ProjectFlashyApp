import '../data/quiz_model.dart';
import '../data/quiz_repository.dart';

/// Nghiệp vụ riêng của Quiz/Test.
///
/// Service không chứa widget và không quản lý Riverpod state. Những quy tắc như
/// quyền Teacher, giới hạn câu hỏi, thời gian làm bài sẽ được đặt tại đây.
class QuizService {
  const QuizService(this._repository);

  final QuizRepository _repository;

  static const supportedStatuses = {'draft', 'published'};

  Future<List<QuizModel>> loadQuizzes({String? status}) {
    if (status != null && !supportedStatuses.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Trạng thái quiz không hợp lệ',
      );
    }
    return _repository.findAll(status: status);
  }

  Future<QuizModel?> loadQuizDetail(int quizId) {
    if (quizId <= 0) {
      throw ArgumentError.value(quizId, 'quizId', 'Quiz ID phải lớn hơn 0');
    }
    return _repository.findById(quizId);
  }
}
