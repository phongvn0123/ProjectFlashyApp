/// Dữ liệu Quiz/Test mà feature Quiz sử dụng.
///
/// Model chỉ chuyển đổi dữ liệu; không gọi SQLite, Firebase hay cập nhật UI.
class QuizModel {
  const QuizModel({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.questionCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.timeLimitSeconds,
    this.shuffleOrder = false,
  });

  final int id;
  final int teacherId;
  final String title;
  final String? description;
  final int? timeLimitSeconds;
  final int questionCount;
  final bool shuffleOrder;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPublished => status == 'published';

  factory QuizModel.fromDatabase(Map<String, Object?> row) {
    return QuizModel(
      id: row['quiz_id'] as int,
      teacherId: row['teacher_id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      timeLimitSeconds: row['time_limit_sec'] as int?,
      questionCount: row['question_count'] as int? ?? 0,
      shuffleOrder: (row['shuffle_order'] as int? ?? 0) == 1,
      status: row['status'] as String? ?? 'draft',
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['quizId'] as int,
      teacherId: json['teacherId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      timeLimitSeconds: json['timeLimitSeconds'] as int?,
      questionCount: json['questionCount'] as int? ?? 0,
      shuffleOrder: json['shuffleOrder'] as bool? ?? false,
      status: json['status'] as String? ?? 'draft',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  Map<String, Object?> toDatabase() => {
    'quiz_id': id,
    'teacher_id': teacherId,
    'title': title,
    'description': description,
    'time_limit_sec': timeLimitSeconds,
    'question_count': questionCount,
    'shuffle_order': shuffleOrder ? 1 : 0,
    'status': status,
    'is_deleted': 0,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };
}
