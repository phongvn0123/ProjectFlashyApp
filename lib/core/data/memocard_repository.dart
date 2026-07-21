import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../models/memocard_models.dart';
import 'app_database.dart';

String _id(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

class MemocardRepository {
  MemocardRepository(this._db);

  final AppDatabase _db;

  Future<void> ensureSeedData() async {
    final db = await _db.database;
    final existing = await db.query('users', limit: 1);
    if (existing.isNotEmpty) {
      await _ensureDemoClassrooms(db);
      return;
    }

    await db.transaction((txn) async {
      const users = [
        AppUser(
          id: 'demo_student',
          username: 'student',
          email: 'student@memocard.test',
          role: 'student',
          fullName: 'Nguyễn Minh Anh',
        ),
        AppUser(
          id: 'demo_teacher',
          username: 'teacher',
          email: 'teacher@memocard.test',
          role: 'teacher',
          fullName: 'Cô Trần Thu Hà',
        ),
        AppUser(
          id: 'demo_admin',
          username: 'admin',
          email: 'admin@memocard.test',
          role: 'admin',
          fullName: 'Quản trị viên',
        ),
      ];
      for (final user in users) {
        await txn.insert('users', {...user.toMap(), 'password': '123456'});
      }

      const ieltsSet = FlashcardSet(
        id: 'set_ielts_vocab',
        ownerId: 'demo_teacher',
        title: 'Từ vựng IELTS cơ bản',
        description: 'Bộ thẻ mẫu để học và sinh bài kiểm tra trắc nghiệm.',
        visibility: 'public',
        cardCount: 6,
      );
      const biologySet = FlashcardSet(
        id: 'set_biology_memory',
        ownerId: 'demo_teacher',
        title: 'Sinh học - Tế bào',
        description: 'Các khái niệm tế bào thường gặp trong bài kiểm tra.',
        visibility: 'public',
        cardCount: 5,
      );
      await txn.insert('flashcard_sets', ieltsSet.toMap());
      await txn.insert('flashcard_sets', biologySet.toMap());

      const cards = [
        Flashcard(
          id: 'card_ielts_1',
          setId: 'set_ielts_vocab',
          front: 'Abundant',
          back: 'Dồi dào',
        ),
        Flashcard(
          id: 'card_ielts_2',
          setId: 'set_ielts_vocab',
          front: 'Benefit',
          back: 'Lợi ích',
        ),
        Flashcard(
          id: 'card_ielts_3',
          setId: 'set_ielts_vocab',
          front: 'Challenge',
          back: 'Thử thách',
        ),
        Flashcard(
          id: 'card_ielts_4',
          setId: 'set_ielts_vocab',
          front: 'Evidence',
          back: 'Bằng chứng',
        ),
        Flashcard(
          id: 'card_ielts_5',
          setId: 'set_ielts_vocab',
          front: 'Improve',
          back: 'Cải thiện',
        ),
        Flashcard(
          id: 'card_ielts_6',
          setId: 'set_ielts_vocab',
          front: 'Reliable',
          back: 'Đáng tin cậy',
        ),
        Flashcard(
          id: 'card_bio_1',
          setId: 'set_biology_memory',
          front: 'Nhân tế bào',
          back: 'Điều khiển hoạt động tế bào',
        ),
        Flashcard(
          id: 'card_bio_2',
          setId: 'set_biology_memory',
          front: 'Ti thể',
          back: 'Tạo năng lượng cho tế bào',
        ),
        Flashcard(
          id: 'card_bio_3',
          setId: 'set_biology_memory',
          front: 'Màng tế bào',
          back: 'Bao bọc và trao đổi chất',
        ),
        Flashcard(
          id: 'card_bio_4',
          setId: 'set_biology_memory',
          front: 'Lục lạp',
          back: 'Quang hợp ở thực vật',
        ),
        Flashcard(
          id: 'card_bio_5',
          setId: 'set_biology_memory',
          front: 'Ribosome',
          back: 'Tổng hợp protein',
        ),
      ];
      for (final card in cards) {
        await txn.insert('flashcards', card.toMap());
      }
    });
    await _ensureDemoClassrooms(db);
  }

  Future<void> _ensureDemoClassrooms(Database db) async {
    const demoClassrooms = [
      Classroom(
        id: 'class_demo_10a1',
        teacherId: 'demo_teacher',
        name: 'Lớp 10A1 - Ghi nhớ thuật ngữ',
        joinCode: '123456',
        isJoinEnabled: true,
      ),
      Classroom(
        id: 'class_demo_10a2',
        teacherId: 'demo_teacher',
        name: 'Lớp 10A2 - Từ vựng nâng cao',
        joinCode: '234567',
        isJoinEnabled: true,
      ),
      Classroom(
        id: 'class_demo_11b1',
        teacherId: 'demo_teacher',
        name: 'Lớp 11B1 - Ôn tập sinh học',
        joinCode: '345678',
        isJoinEnabled: true,
      ),
    ];
    await db.transaction((txn) async {
      for (final classroom in demoClassrooms) {
        await txn.insert(
          'classrooms',
          classroom.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await txn.insert('class_members', {
          'class_id': classroom.id,
          'user_id': 'demo_teacher',
          'role': 'teacher',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await txn.insert('class_members', {
          'class_id': classroom.id,
          'user_id': 'demo_student',
          'role': 'student',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final db = await _db.database;
    final user = AppUser(
      id: _id('user'),
      username: username.trim(),
      email: email.trim(),
      role: role,
      fullName: username.trim(),
    );
    await db.insert('users', {...user.toMap(), 'password': password});
    return user;
  }

  Future<AppUser?> login(String account, String password) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: '(email = ? OR username = ?) AND password = ?',
      whereArgs: [account.trim(), account.trim(), password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final user = AppUser.fromMap(rows.first);
    if (user.status != 'active') return null;
    return user;
  }

  Future<AppUser?> userById(String id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<List<AppUser>> users() async {
    final db = await _db.database;
    final rows = await db.query('users', orderBy: 'username');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    final db = await _db.database;
    await db.update(
      'users',
      {'role': role},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<FlashcardSet> createSet({
    required String ownerId,
    required String title,
    required String description,
    required List<(String, String)> cards,
    String visibility = 'public',
  }) async {
    final db = await _db.database;
    final set = FlashcardSet(
      id: _id('set'),
      ownerId: ownerId,
      title: title.trim(),
      description: description.trim(),
      visibility: visibility,
      cardCount: cards.length,
    );
    await db.transaction((txn) async {
      await txn.insert('flashcard_sets', set.toMap());
      for (final card in cards) {
        await txn.insert(
          'flashcards',
          Flashcard(
            id: _id('card'),
            setId: set.id,
            front: card.$1.trim(),
            back: card.$2.trim(),
          ).toMap(),
        );
      }
    });
    return set;
  }

  Future<List<FlashcardSet>> sets({String query = ''}) async {
    final db = await _db.database;
    final rows = await db.query(
      'flashcard_sets',
      where: query.trim().isEmpty ? null : 'title LIKE ?',
      whereArgs: query.trim().isEmpty ? null : ['%${query.trim()}%'],
      orderBy: 'title',
    );
    return rows.map(FlashcardSet.fromMap).toList();
  }

  Future<List<Flashcard>> cards(String setId) async {
    final db = await _db.database;
    final rows = await db.query(
      'flashcards',
      where: 'set_id = ?',
      whereArgs: [setId],
    );
    return rows.map(Flashcard.fromMap).toList();
  }

  Future<void> saveLearningResult({
    required String userId,
    required String setId,
    required int known,
    required int unknown,
  }) async {
    final db = await _db.database;
    await db.insert('learning_sessions', {
      'id': _id('learn'),
      'user_id': userId,
      'set_id': setId,
      'known_count': known,
      'unknown_count': unknown,
      'status': 'completed',
    });
  }

  Future<List<Map<String, Object?>>> learningHistory(String userId) async {
    final db = await _db.database;
    return db.rawQuery(
      '''
      SELECT s.title, l.known_count, l.unknown_count
      FROM learning_sessions l
      JOIN flashcard_sets s ON s.id = l.set_id
      WHERE l.user_id = ?
      ORDER BY l.id DESC
    ''',
      [userId],
    );
  }

  Future<Classroom> createClass(String teacherId, String name) async {
    final db = await _db.database;
    final classroom = Classroom(
      id: _id('class'),
      teacherId: teacherId,
      name: name.trim(),
      joinCode: (100000 + Random().nextInt(900000)).toString(),
      isJoinEnabled: true,
    );
    await db.insert('classrooms', classroom.toMap());
    await db.insert('class_members', {
      'class_id': classroom.id,
      'user_id': teacherId,
      'role': 'teacher',
    });
    return classroom;
  }

  Future<List<Classroom>> classrooms(String userId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.* FROM classrooms c
      JOIN class_members m ON m.class_id = c.id
      WHERE m.user_id = ?
      ORDER BY c.name
    ''',
      [userId],
    );
    return rows.map(Classroom.fromMap).toList();
  }

  Future<Classroom?> joinClass(String userId, String joinCode) async {
    final db = await _db.database;
    final rows = await db.query(
      'classrooms',
      where: 'join_code = ? AND is_join_enabled = 1',
      whereArgs: [joinCode.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final classroom = Classroom.fromMap(rows.first);
    await db.insert('class_members', {
      'class_id': classroom.id,
      'user_id': userId,
      'role': 'student',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    return classroom;
  }

  Future<List<QuizQuestion>> generateQuiz(String setId) async {
    final sourceCards = await cards(setId);
    if (sourceCards.length < 4) return const [];
    return generateQuizFromSets(
      setIds: [setId],
      questionCount: min(10, sourceCards.length),
      questionOrder: 'sequential',
    );
  }

  Future<List<QuizQuestion>> generateQuizFromSets({
    required List<String> setIds,
    required int questionCount,
    required String questionOrder,
  }) async {
    final sourceCards = <Flashcard>[];
    for (final setId in setIds.toSet()) {
      sourceCards.addAll(await cards(setId));
    }
    if (sourceCards.length < 4 ||
        questionCount < 1 ||
        questionCount > sourceCards.length) {
      return const [];
    }

    final candidates = List<Flashcard>.of(sourceCards);
    if (questionOrder == 'random') candidates.shuffle();

    return candidates
        .take(questionCount)
        .map((card) => _questionFromCard(card, sourceCards))
        .toList();
  }

  QuizQuestion _questionFromCard(Flashcard card, List<Flashcard> sourceCards) {
    final wrongAnswers = sourceCards
        .where((item) => item.id != card.id && item.back != card.back)
        .map((item) => item.back)
        .toSet()
        .take(3);
    final options = <String>[card.back, ...wrongAnswers];
    return QuizQuestion(prompt: card.front, options: options, correctIndex: 0);
  }

  Future<TeacherQuiz> createQuiz({
    required String teacherId,
    required List<String> setIds,
    required String title,
    required int timeLimitMinutes,
    required String questionOrder,
    required List<QuizQuestion> questions,
  }) async {
    if (title.trim().isEmpty || setIds.isEmpty || questions.isEmpty) {
      throw ArgumentError('Thông tin bài kiểm tra không hợp lệ.');
    }
    if (timeLimitMinutes < 1 || timeLimitMinutes > 180) {
      throw ArgumentError('Thời gian làm bài phải từ 1 đến 180 phút.');
    }
    final db = await _db.database;
    final quiz = TeacherQuiz(
      id: _id('quiz'),
      teacherId: teacherId,
      setId: setIds.first,
      title: title.trim(),
      questionCount: questions.length,
      status: 'draft',
      timeLimitMinutes: timeLimitMinutes,
      questionOrder: questionOrder,
      answerOrder: 'fixed',
    );
    await db.transaction((txn) async {
      await txn.insert('quizzes', quiz.toMap());
      for (var i = 0; i < setIds.length; i++) {
        await txn.insert('quiz_source_sets', {
          'quiz_id': quiz.id,
          'set_id': setIds[i],
          'order_index': i,
        });
      }
      for (var i = 0; i < questions.length; i++) {
        final question = questions[i];
        await txn.insert(
          'quiz_questions_demo',
          TeacherQuizQuestion(
            id: _id('quiz_question'),
            quizId: quiz.id,
            prompt: question.prompt,
            correctAnswer: question.options[question.correctIndex],
            orderIndex: i,
            options: question.options,
            correctIndex: question.correctIndex,
          ).toMap(),
        );
      }
    });
    return quiz;
  }

  Future<void> publishQuiz({
    required String quizId,
    required String teacherId,
    required List<String> classroomIds,
  }) async {
    if (classroomIds.isEmpty) {
      throw ArgumentError('Vui lòng chọn ít nhất một lớp học.');
    }
    await _db.ensureQuizPublishingSchema();
    final db = await _db.database;
    await db.transaction((txn) async {
      final quizRows = await txn.query(
        'quizzes',
        columns: ['id', 'question_count', 'status'],
        where: 'id = ? AND teacher_id = ? AND status != ?',
        whereArgs: [quizId, teacherId, 'deleted'],
        limit: 1,
      );
      if (quizRows.isEmpty ||
          ((quizRows.first['question_count'] as int?) ?? 0) < 1) {
        throw StateError('Bài kiểm tra không hợp lệ để xuất bản.');
      }
      final uniqueClassroomIds = classroomIds.toSet();
      for (final classroomId in uniqueClassroomIds) {
        final classroomRows = await txn.query(
          'classrooms',
          columns: ['id'],
          where: 'id = ? AND teacher_id = ?',
          whereArgs: [classroomId, teacherId],
          limit: 1,
        );
        final existingAssignment = await txn.query(
          'quiz_classroom_assignments',
          columns: ['quiz_id'],
          where: 'quiz_id = ? AND classroom_id = ?',
          whereArgs: [quizId, classroomId],
          limit: 1,
        );
        if (classroomRows.isEmpty || existingAssignment.isNotEmpty) {
          throw StateError('Lớp học không hợp lệ hoặc đã nhận bài kiểm tra.');
        }
        await txn.insert(
          'quiz_classroom_assignments',
          {
            'quiz_id': quizId,
            'classroom_id': classroomId,
            'published_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await txn.update(
        'quizzes',
        {'status': 'published', 'assigned_class_id': uniqueClassroomIds.first},
        where: 'id = ?',
        whereArgs: [quizId],
      );
    });
  }

  Future<List<Classroom>> availableClassroomsForQuiz(
    String teacherId,
    String quizId,
  ) async {
    await _db.ensureQuizPublishingSchema();
    final db = await _db.database;
    await _ensureDemoClassrooms(db);
    final rows = await db.rawQuery(
      '''
      SELECT c.* FROM classrooms c
      WHERE c.teacher_id = ?
        AND NOT EXISTS (
          SELECT 1 FROM quiz_classroom_assignments a
          WHERE a.quiz_id = ? AND a.classroom_id = c.id
        )
      ORDER BY c.name
      ''',
      [teacherId, quizId],
    );
    return rows.map(Classroom.fromMap).toList();
  }

  Future<List<Classroom>> assignedClassroomsForQuiz(String quizId) async {
    await _db.ensureQuizPublishingSchema();
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.* FROM classrooms c
      JOIN quiz_classroom_assignments a ON a.classroom_id = c.id
      WHERE a.quiz_id = ?
      ORDER BY c.name
      ''',
      [quizId],
    );
    return rows.map(Classroom.fromMap).toList();
  }

  Future<List<StudentAssignedQuiz>> assignedQuizzesForStudent(
    String studentId,
  ) async {
    await _db.ensureQuizPublishingSchema();
    await _db.ensureStudentQuizSchema();
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        q.*,
        GROUP_CONCAT(DISTINCT c.id) AS classroom_id,
        GROUP_CONCAT(DISTINCT c.name) AS classroom_name,
        COALESCE(NULLIF(u.full_name, ''), u.username) AS teacher_name,
        MAX(a.published_at) AS published_at,
        EXISTS (
          SELECT 1 FROM quiz_attempts qa
          WHERE qa.user_id = ?
            AND qa.quiz_id = q.id
            AND qa.status = 'completed'
        ) AS is_completed,
        (
          SELECT qa.score FROM quiz_attempts qa
          WHERE qa.user_id = ?
            AND qa.quiz_id = q.id
            AND qa.status = 'completed'
          ORDER BY qa.completed_at DESC, qa.id DESC
          LIMIT 1
        ) AS latest_score,
        (
          SELECT qa.total FROM quiz_attempts qa
          WHERE qa.user_id = ?
            AND qa.quiz_id = q.id
            AND qa.status = 'completed'
          ORDER BY qa.completed_at DESC, qa.id DESC
          LIMIT 1
        ) AS latest_total
      FROM quizzes q
      JOIN quiz_classroom_assignments a ON a.quiz_id = q.id
      JOIN class_members m ON m.class_id = a.classroom_id
      JOIN classrooms c ON c.id = a.classroom_id
      JOIN users u ON u.id = q.teacher_id
      WHERE m.user_id = ?
        AND m.role = 'student'
        AND q.status = 'published'
      GROUP BY q.id
      ORDER BY MAX(a.published_at) DESC, q.title
      ''',
      [studentId, studentId, studentId, studentId],
    );
    return rows.map(StudentAssignedQuiz.fromMap).toList();
  }

  Future<List<TeacherQuiz>> quizzesByTeacher(String teacherId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quizzes',
      where: 'teacher_id = ? AND status != ?',
      whereArgs: [teacherId, 'deleted'],
      orderBy: 'id DESC',
    );
    return rows.map(TeacherQuiz.fromMap).toList();
  }

  Future<List<TeacherQuiz>> archivedQuizzesByTeacher(String teacherId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quizzes',
      where: 'teacher_id = ? AND status = ?',
      whereArgs: [teacherId, 'deleted'],
      orderBy: 'id DESC',
    );
    return rows.map(TeacherQuiz.fromMap).toList();
  }

  Future<bool> archiveQuiz({
    required String quizId,
    required String teacherId,
  }) async {
    await _db.ensureQuizPublishingSchema();
    final db = await _db.database;
    return db.transaction((txn) async {
      final rows = await txn.query(
        'quizzes',
        columns: ['id', 'status'],
        where: 'id = ? AND teacher_id = ?',
        whereArgs: [quizId, teacherId],
        limit: 1,
      );
      if (rows.isEmpty || rows.first['status'] == 'deleted') return false;
      await txn.delete(
        'quiz_classroom_assignments',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
      final updated = await txn.update(
        'quizzes',
        {'status': 'deleted', 'assigned_class_id': null},
        where: 'id = ? AND teacher_id = ?',
        whereArgs: [quizId, teacherId],
      );
      return updated == 1;
    });
  }

  Future<bool> restoreQuiz({
    required String quizId,
    required String teacherId,
  }) async {
    final db = await _db.database;
    final updated = await db.update(
      'quizzes',
      {'status': 'draft', 'assigned_class_id': null},
      where: 'id = ? AND teacher_id = ? AND status = ?',
      whereArgs: [quizId, teacherId, 'deleted'],
    );
    return updated == 1;
  }

  Future<TeacherQuiz?> quizById(String quizId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quizzes',
      where: 'id = ?',
      whereArgs: [quizId],
    );
    return rows.isEmpty ? null : TeacherQuiz.fromMap(rows.first);
  }

  Future<List<TeacherQuizQuestion>> quizQuestions(String quizId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quiz_questions_demo',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'order_index',
    );
    return rows.map(TeacherQuizQuestion.fromMap).toList();
  }

  Future<List<String>> quizSourceSetIds(String quizId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quiz_source_sets',
      columns: ['set_id'],
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'order_index',
    );
    if (rows.isNotEmpty) {
      return rows.map((row) => row['set_id']! as String).toList();
    }
    final quiz = await quizById(quizId);
    return quiz == null ? const [] : [quiz.setId];
  }

  Future<List<Flashcard>> _quizSourceCards(String quizId) async {
    final sourceCards = <Flashcard>[];
    for (final setId in await quizSourceSetIds(quizId)) {
      sourceCards.addAll(await cards(setId));
    }
    return sourceCards;
  }

  Future<int> quizSourceCardCount(String quizId) async {
    return (await _quizSourceCards(quizId)).length;
  }

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    required int timeLimitMinutes,
    required String questionOrder,
    required List<TeacherQuizQuestion> questions,
  }) async {
    if (title.trim().isEmpty || questions.isEmpty) {
      throw ArgumentError('Thông tin bài kiểm tra không hợp lệ.');
    }
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        'quizzes',
        {
          'title': title.trim(),
          'time_limit_minutes': timeLimitMinutes,
          'question_order': questionOrder,
          'answer_order': 'fixed',
          'question_count': questions.length,
        },
        where: 'id = ?',
        whereArgs: [quizId],
      );
      await txn.delete(
        'quiz_questions_demo',
        where: 'quiz_id = ?',
        whereArgs: [quizId],
      );
      for (var i = 0; i < questions.length; i++) {
        await txn.insert('quiz_questions_demo', {
          ...questions[i].toMap(),
          'quiz_id': quizId,
          'order_index': i,
        });
      }
    });
  }

  Future<List<TeacherQuizQuestion>> generateAdditionalQuizQuestions({
    required String quizId,
    required List<TeacherQuizQuestion> existingQuestions,
    required int count,
  }) async {
    if (count < 1) return const [];
    final sourceCards = await _quizSourceCards(quizId);
    final usedPrompts = existingQuestions.map((item) => item.prompt).toSet();
    final available = sourceCards
        .where((card) => !usedPrompts.contains(card.front))
        .take(count)
        .toList();
    return available.indexed.map((entry) {
      final generated = _questionFromCard(entry.$2, sourceCards);
      return TeacherQuizQuestion(
        id: _id('quiz_question'),
        quizId: quizId,
        prompt: generated.prompt,
        correctAnswer: generated.options[generated.correctIndex],
        orderIndex: existingQuestions.length + entry.$1,
        options: generated.options,
        correctIndex: generated.correctIndex,
      );
    }).toList();
  }

  Future<void> saveQuizAttempt(
    String userId,
    String setId,
    int score,
    int total, {
    String? quizId,
  }) async {
    await _db.ensureStudentQuizSchema();
    final db = await _db.database;
    await db.insert('quiz_attempts', {
      'id': _id('attempt'),
      'user_id': userId,
      'set_id': setId,
      'quiz_id': quizId,
      'score': score,
      'total': total,
      'status': 'completed',
      'started_at': DateTime.now().toIso8601String(),
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<QuizAttemptSession> startQuizAttempt({
    required String userId,
    required TeacherQuiz quiz,
  }) async {
    await _db.ensureStudentQuizSchema();
    final db = await _db.database;
    return db.transaction((txn) async {
      final completed = await txn.query(
        'quiz_attempts',
        columns: ['id'],
        where: 'user_id = ? AND quiz_id = ? AND status = ?',
        whereArgs: [userId, quiz.id, 'completed'],
        limit: 1,
      );
      if (completed.isNotEmpty) {
        throw StateError('Bài kiểm tra này đã được hoàn thành.');
      }

      final active = await txn.query(
        'quiz_attempts',
        columns: ['id', 'started_at'],
        where: 'user_id = ? AND quiz_id = ? AND status = ?',
        whereArgs: [userId, quiz.id, 'in_progress'],
        limit: 1,
      );
      if (active.isNotEmpty) {
        final startedAt = DateTime.tryParse(
          (active.first['started_at'] as String?) ?? '',
        );
        return QuizAttemptSession(
          id: active.first['id'] as String,
          startedAt: startedAt ?? DateTime.now(),
        );
      }

      final now = DateTime.now();
      final attemptId = _id('attempt');
      await txn.insert('quiz_attempts', {
        'id': attemptId,
        'user_id': userId,
        'set_id': quiz.setId,
        'quiz_id': quiz.id,
        'score': 0,
        'total': quiz.questionCount,
        'status': 'in_progress',
        'started_at': now.toIso8601String(),
      });
      return QuizAttemptSession(id: attemptId, startedAt: now);
    });
  }

  Future<void> completeQuizAttempt({
    required String attemptId,
    required int score,
    required int total,
    required List<QuizQuestion> questions,
    required List<int?> selectedAnswers,
  }) async {
    await _db.ensureStudentQuizSchema();
    await _db.ensureQuizResultSchema();
    final db = await _db.database;
    await db.transaction((txn) async {
      for (var index = 0; index < questions.length; index++) {
        final question = questions[index];
        if (question.id == null) continue;
        await txn.insert('quiz_attempt_answers', {
          'attempt_id': attemptId,
          'question_id': question.id,
          'selected_index': selectedAnswers[index],
          'correct_index': question.correctIndex,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await txn.update(
        'quiz_attempts',
        {
          'score': score,
          'total': total,
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND status = ?',
        whereArgs: [attemptId, 'in_progress'],
      );
    });
  }

  Future<ClassQuizPerformance> classQuizPerformance({
    required String quizId,
    required String classroomId,
  }) async {
    await _db.ensureStudentQuizSchema();
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        u.id AS student_id,
        COALESCE(NULLIF(u.full_name, ''), u.username) AS student_name,
        qa.id AS attempt_id,
        qa.score,
        qa.total,
        qa.completed_at
      FROM class_members m
      JOIN users u ON u.id = m.user_id
      LEFT JOIN quiz_attempts qa ON qa.id = (
        SELECT qa2.id FROM quiz_attempts qa2
        WHERE qa2.user_id = u.id
          AND qa2.quiz_id = ?
          AND qa2.status = 'completed'
        ORDER BY qa2.completed_at DESC, qa2.id DESC
        LIMIT 1
      )
      WHERE m.class_id = ? AND m.role = 'student'
      ORDER BY
        CASE WHEN qa.id IS NULL THEN 1 ELSE 0 END,
        CAST(qa.score AS REAL) / NULLIF(qa.total, 0) DESC,
        student_name
      ''',
      [quizId, classroomId],
    );
    final students = rows.map(StudentQuizResult.fromMap).toList();
    final completedScores = students
        .map((student) => student.scoreOutOfTen)
        .whereType<double>()
        .toList();
    return ClassQuizPerformance(
      students: students,
      assignedCount: students.length,
      completedCount: completedScores.length,
      notStartedCount: students.length - completedScores.length,
      averageScore: completedScores.isEmpty
          ? null
          : completedScores.reduce((a, b) => a + b) / completedScores.length,
      highestScore: completedScores.isEmpty
          ? null
          : completedScores.reduce((a, b) => a > b ? a : b),
      lowestScore: completedScores.isEmpty
          ? null
          : completedScores.reduce((a, b) => a < b ? a : b),
    );
  }

  Future<List<QuizAnswerReview>> quizAttemptAnswerReviews(
    String attemptId,
  ) async {
    await _db.ensureQuizResultSchema();
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        q.prompt,
        q.correct_answer,
        q.options_json,
        q.order_index,
        a.selected_index,
        a.correct_index
      FROM quiz_attempt_answers a
      JOIN quiz_questions_demo q ON q.id = a.question_id
      WHERE a.attempt_id = ?
      ORDER BY q.order_index
      ''',
      [attemptId],
    );
    return rows.map(QuizAnswerReview.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> quizHistory(String userId) async {
    final db = await _db.database;
    return db.rawQuery(
      '''
      SELECT s.title, q.score, q.total
      FROM quiz_attempts q
      JOIN flashcard_sets s ON s.id = q.set_id
      WHERE q.user_id = ?
        AND q.status = 'completed'
      ORDER BY q.id DESC
    ''',
      [userId],
    );
  }
}
