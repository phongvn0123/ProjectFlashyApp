import '../../../core/errors/api_exception.dart';

class SaveQuizRequest {
  const SaveQuizRequest({
    required this.title,
    required this.status,
    required this.questionCount,
    required this.shuffleOrder,
    this.description,
    this.timeLimitSeconds,
  });

  final String title;
  final String? description;
  final int? timeLimitSeconds;
  final int questionCount;
  final bool shuffleOrder;
  final String status;

  factory SaveQuizRequest.fromJson(Map<String, Object?> json) {
    final title = (json['title'] as String? ?? '').trim();
    final description = (json['description'] as String?)?.trim();
    final timeLimit = json['timeLimitSeconds'];
    final questionCount = json['questionCount'];
    final status = json['status'] as String? ?? 'draft';

    if (title.isEmpty) {
      throw ApiException.badRequest('Tiêu đề Quiz/Test không được để trống.');
    }
    if (title.length > 150) {
      throw ApiException.badRequest('Tiêu đề Quiz/Test tối đa 150 ký tự.');
    }
    if (timeLimit != null && (timeLimit is! int || timeLimit <= 0)) {
      throw ApiException.badRequest('Thời gian làm bài phải lớn hơn 0.');
    }
    if (questionCount != null && (questionCount is! int || questionCount < 0)) {
      throw ApiException.badRequest('Số câu hỏi không hợp lệ.');
    }
    if (!{'draft', 'published', 'closed'}.contains(status)) {
      throw ApiException.badRequest('Trạng thái Quiz/Test không hợp lệ.');
    }

    return SaveQuizRequest(
      title: title,
      description: description?.isEmpty == true ? null : description,
      timeLimitSeconds: timeLimit as int?,
      questionCount: questionCount as int? ?? 0,
      shuffleOrder: json['shuffleOrder'] as bool? ?? false,
      status: status,
    );
  }
}
