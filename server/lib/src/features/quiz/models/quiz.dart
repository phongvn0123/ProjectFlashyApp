class Quiz {
  const Quiz({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.questionCount,
    required this.shuffleOrder,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.timeLimitSeconds,
  });

  final int id;
  final int teacherId;
  final String title;
  final String? description;
  final int? timeLimitSeconds;
  final int questionCount;
  final bool shuffleOrder;
  final String status;
  final int createdAt;
  final int updatedAt;

  factory Quiz.fromRow(Map<String, Object?> row) {
    return Quiz(
      id: row['quiz_id'] as int,
      teacherId: row['teacher_id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      timeLimitSeconds: row['time_limit_sec'] as int?,
      questionCount: row['question_count'] as int? ?? 0,
      shuffleOrder: (row['shuffle_order'] as int? ?? 0) == 1,
      status: row['status'] as String,
      createdAt: row['created_at'] as int,
      updatedAt: row['updated_at'] as int,
    );
  }

  Map<String, Object?> toJson() => {
    'quizId': id,
    'teacherId': teacherId,
    'title': title,
    'description': description,
    'timeLimitSeconds': timeLimitSeconds,
    'questionCount': questionCount,
    'shuffleOrder': shuffleOrder,
    'status': status,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
