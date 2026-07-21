import 'dart:convert';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.fullName = '',
    this.status = 'active',
  });

  final String id;
  final String username;
  final String email;
  final String role;
  final String fullName;
  final String status;

  Map<String, Object?> toMap() => {
    'id': id,
    'username': username,
    'email': email,
    'role': role,
    'full_name': fullName,
    'status': status,
  };

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as String,
    username: map['username'] as String,
    email: map['email'] as String,
    role: map['role'] as String,
    fullName: (map['full_name'] as String?) ?? '',
    status: (map['status'] as String?) ?? 'active',
  );
}

class FlashcardSet {
  const FlashcardSet({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.visibility,
    required this.cardCount,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String visibility;
  final int cardCount;

  Map<String, Object?> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'title': title,
    'description': description,
    'visibility': visibility,
    'card_count': cardCount,
  };

  factory FlashcardSet.fromMap(Map<String, Object?> map) => FlashcardSet(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String,
    title: map['title'] as String,
    description: (map['description'] as String?) ?? '',
    visibility: (map['visibility'] as String?) ?? 'private',
    cardCount: (map['card_count'] as int?) ?? 0,
  );
}

class Flashcard {
  const Flashcard({
    required this.id,
    required this.setId,
    required this.front,
    required this.back,
  });

  final String id;
  final String setId;
  final String front;
  final String back;

  Map<String, Object?> toMap() => {
    'id': id,
    'set_id': setId,
    'front': front,
    'back': back,
  };

  factory Flashcard.fromMap(Map<String, Object?> map) => Flashcard(
    id: map['id'] as String,
    setId: map['set_id'] as String,
    front: map['front'] as String,
    back: map['back'] as String,
  );
}

class Classroom {
  const Classroom({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.joinCode,
    required this.isJoinEnabled,
  });

  final String id;
  final String teacherId;
  final String name;
  final String joinCode;
  final bool isJoinEnabled;

  Map<String, Object?> toMap() => {
    'id': id,
    'teacher_id': teacherId,
    'name': name,
    'join_code': joinCode,
    'is_join_enabled': isJoinEnabled ? 1 : 0,
  };

  factory Classroom.fromMap(Map<String, Object?> map) => Classroom(
    id: map['id'] as String,
    teacherId: map['teacher_id'] as String,
    name: map['name'] as String,
    joinCode: map['join_code'] as String,
    isJoinEnabled: ((map['is_join_enabled'] as int?) ?? 1) == 1,
  );
}

class QuizQuestion {
  const QuizQuestion({
    this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String? id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class TeacherQuiz {
  const TeacherQuiz({
    required this.id,
    required this.teacherId,
    required this.setId,
    required this.title,
    required this.questionCount,
    required this.status,
    this.timeLimitMinutes = 15,
    this.questionOrder = 'sequential',
    this.answerOrder = 'fixed',
    this.assignedClassId,
  });

  final String id;
  final String teacherId;
  final String setId;
  final String title;
  final int questionCount;
  final String status;
  final int timeLimitMinutes;
  final String questionOrder;
  final String answerOrder;
  final String? assignedClassId;

  Map<String, Object?> toMap() => {
    'id': id,
    'teacher_id': teacherId,
    'set_id': setId,
    'title': title,
    'question_count': questionCount,
    'status': status,
    'time_limit_minutes': timeLimitMinutes,
    'question_order': questionOrder,
    'answer_order': answerOrder,
    'assigned_class_id': assignedClassId,
  };

  factory TeacherQuiz.fromMap(Map<String, Object?> map) => TeacherQuiz(
    id: map['id'] as String,
    teacherId: map['teacher_id'] as String,
    setId: map['set_id'] as String,
    title: map['title'] as String,
    questionCount: (map['question_count'] as int?) ?? 0,
    status: (map['status'] as String?) ?? 'draft',
    timeLimitMinutes: (map['time_limit_minutes'] as int?) ?? 15,
    questionOrder: (map['question_order'] as String?) ?? 'sequential',
    answerOrder: (map['answer_order'] as String?) ?? 'fixed',
    assignedClassId: map['assigned_class_id'] as String?,
  );
}

class StudentAssignedQuiz {
  const StudentAssignedQuiz({
    required this.quiz,
    required this.teacherName,
    required this.classroomId,
    required this.classroomName,
    required this.publishedAt,
    required this.isCompleted,
    this.latestScore,
    this.latestTotal,
  });

  final TeacherQuiz quiz;
  final String teacherName;
  final String classroomId;
  final String classroomName;
  final DateTime? publishedAt;
  final bool isCompleted;
  final int? latestScore;
  final int? latestTotal;

  factory StudentAssignedQuiz.fromMap(Map<String, Object?> map) {
    final publishedAtValue = map['published_at'] as String?;
    return StudentAssignedQuiz(
      quiz: TeacherQuiz.fromMap(map),
      teacherName: (map['teacher_name'] as String?) ?? '',
      classroomId: map['classroom_id'] as String,
      classroomName: (map['classroom_name'] as String).replaceAll(',', ', '),
      publishedAt: publishedAtValue == null
          ? null
          : DateTime.tryParse(publishedAtValue),
      isCompleted: ((map['is_completed'] as int?) ?? 0) == 1,
      latestScore: map['latest_score'] as int?,
      latestTotal: map['latest_total'] as int?,
    );
  }
}

class QuizAttemptSession {
  const QuizAttemptSession({required this.id, required this.startedAt});

  final String id;
  final DateTime startedAt;
}

class StudentQuizResult {
  const StudentQuizResult({
    required this.studentId,
    required this.studentName,
    required this.status,
    this.attemptId,
    this.score,
    this.total,
    this.submittedAt,
  });

  final String studentId;
  final String studentName;
  final String status;
  final String? attemptId;
  final int? score;
  final int? total;
  final DateTime? submittedAt;

  double? get scoreOutOfTen {
    if (score == null || total == null || total == 0) return null;
    return score! / total! * 10;
  }

  factory StudentQuizResult.fromMap(Map<String, Object?> map) {
    final submittedAtValue = map['completed_at'] as String?;
    return StudentQuizResult(
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      status: map['attempt_id'] == null ? 'not_started' : 'completed',
      attemptId: map['attempt_id'] as String?,
      score: map['score'] as int?,
      total: map['total'] as int?,
      submittedAt: submittedAtValue == null
          ? null
          : DateTime.tryParse(submittedAtValue),
    );
  }
}

class ClassQuizPerformance {
  const ClassQuizPerformance({
    required this.students,
    required this.assignedCount,
    required this.completedCount,
    required this.notStartedCount,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
  });

  final List<StudentQuizResult> students;
  final int assignedCount;
  final int completedCount;
  final int notStartedCount;
  final double? averageScore;
  final double? highestScore;
  final double? lowestScore;
}

class QuizAnswerReview {
  const QuizAnswerReview({
    required this.prompt,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.orderIndex,
  });

  final String prompt;
  final String? selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int orderIndex;

  factory QuizAnswerReview.fromMap(Map<String, Object?> map) {
    final options = _decodeStringList(map['options_json']);
    final selectedIndex = map['selected_index'] as int?;
    final correctIndex = (map['correct_index'] as int?) ?? 0;
    return QuizAnswerReview(
      prompt: map['prompt'] as String,
      selectedAnswer:
          selectedIndex != null &&
              selectedIndex >= 0 &&
              selectedIndex < options.length
          ? options[selectedIndex]
          : null,
      correctAnswer: correctIndex >= 0 && correctIndex < options.length
          ? options[correctIndex]
          : map['correct_answer'] as String,
      isCorrect: selectedIndex != null && selectedIndex == correctIndex,
      orderIndex: (map['order_index'] as int?) ?? 0,
    );
  }
}

class TeacherQuizQuestion {
  const TeacherQuizQuestion({
    required this.id,
    required this.quizId,
    required this.prompt,
    required this.correctAnswer,
    required this.orderIndex,
    this.options = const [],
    this.correctIndex = 0,
  });

  final String id;
  final String quizId;
  final String prompt;
  final String correctAnswer;
  final int orderIndex;
  final List<String> options;
  final int correctIndex;

  Map<String, Object?> toMap() => {
    'id': id,
    'quiz_id': quizId,
    'prompt': prompt,
    'correct_answer': correctAnswer,
    'order_index': orderIndex,
    'options_json': jsonEncode(options),
    'correct_index': correctIndex,
  };

  factory TeacherQuizQuestion.fromMap(Map<String, Object?> map) =>
      TeacherQuizQuestion(
        id: map['id'] as String,
        quizId: map['quiz_id'] as String,
        prompt: map['prompt'] as String,
        correctAnswer: map['correct_answer'] as String,
        orderIndex: (map['order_index'] as int?) ?? 0,
        options: _decodeStringList(map['options_json']),
        correctIndex: (map['correct_index'] as int?) ?? 0,
      );
}

List<String> _decodeStringList(Object? value) {
  if (value is! String || value.isEmpty) return const [];
  try {
    return (jsonDecode(value) as List<dynamic>).cast<String>();
  } catch (_) {
    return const [];
  }
}
