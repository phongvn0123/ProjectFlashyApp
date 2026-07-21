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
    if (existing.isNotEmpty) return;

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

      const classroom = Classroom(
        id: 'class_demo_10a1',
        teacherId: 'demo_teacher',
        name: 'Lớp 10A1 - Ghi nhớ thuật ngữ',
        joinCode: '123456',
        isJoinEnabled: true,
      );
      await txn.insert('classrooms', classroom.toMap());
      await txn.insert('class_members', {
        'class_id': classroom.id,
        'user_id': 'demo_teacher',
        'role': 'teacher',
      });
      await txn.insert('class_members', {
        'class_id': classroom.id,
        'user_id': 'demo_student',
        'role': 'student',
      });
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
  //phuoc
  Future<FlashcardSet?> setById(String setId) async {
    final db = await _db.database;

    final rows = await db.query(
      'flashcard_sets',
      where: 'id = ?',
      whereArgs: [setId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return FlashcardSet.fromMap(rows.first);
  }
  Future<bool> isSetFavorite({
    required String userId,
    required String setId,
  }) async {
    final db = await _db.database;

    final rows = await db.query(
      'favorite_flashcard_sets',
      where: 'user_id = ? AND set_id = ?',
      whereArgs: [userId, setId],
      limit: 1,
    );

    return rows.isNotEmpty;
  }
  Future<bool> toggleSetFavorite({
    required String userId,
    required String setId,
  }) async {
    final db = await _db.database;

    return db.transaction((txn) async {
      final existing = await txn.query(
        'favorite_flashcard_sets',
        where: 'user_id = ? AND set_id = ?',
        whereArgs: [userId, setId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await txn.delete(
          'favorite_flashcard_sets',
          where: 'user_id = ? AND set_id = ?',
          whereArgs: [userId, setId],
        );

        return false;
      }

      await txn.insert(
        'favorite_flashcard_sets',
        {
          'user_id': userId,
          'set_id': setId,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      return true;
    });
  }
  Future<Set<String>> favoriteSetIds(String userId) async {
    final db = await _db.database;

    final rows = await db.query(
      'favorite_flashcard_sets',
      columns: ['set_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return rows.map((row) => row['set_id'] as String).toSet();
  }
  Future<List<FlashcardSet>> favoriteSets(
      String userId, {
        String query = '',
      }) async {
    final db = await _db.database;
    final normalizedQuery = query.trim();

    final rows = await db.rawQuery(
      '''
    SELECT s.*
    FROM flashcard_sets s
    INNER JOIN favorite_flashcard_sets f
      ON f.set_id = s.id
    WHERE f.user_id = ?
      AND (? = '' OR s.title LIKE ?)
    ORDER BY f.created_at DESC
    ''',
      [
        userId,
        normalizedQuery,
        '%$normalizedQuery%',
      ],
    );

    return rows.map(FlashcardSet.fromMap).toList();
  }
  Future<void> deleteSet(String setId) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      await txn.delete(
        'favorite_flashcard_sets',
        where: 'set_id = ?',
        whereArgs: [setId],
      );

      await txn.delete(
        'flashcards',
        where: 'set_id = ?',
        whereArgs: [setId],
      );

      await txn.delete(
        'flashcard_sets',
        where: 'id = ?',
        whereArgs: [setId],
      );
    });
  }

  Future<void> updateSet({
    required String setId,
    required String title,
    required String description,
    required String visibility,
    required List<(String, String)> cards,
  }) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // Cập nhật thông tin bộ thẻ.
      await txn.update(
        'flashcard_sets',
        {
          'title': title.trim(),
          'description': description.trim(),
          'visibility': visibility,
          'card_count': cards.length,
        },
        where: 'id = ?',
        whereArgs: [setId],
      );

      // Xóa các thẻ cũ.
      await txn.delete(
        'flashcards',
        where: 'set_id = ?',
        whereArgs: [setId],
      );

      // Thêm lại danh sách thẻ mới.
      for (final card in cards) {
        await txn.insert(
          'flashcards',
          Flashcard(
            id: _id('card'),
            setId: setId,
            front: card.$1.trim(),
            back: card.$2.trim(),
          ).toMap(),
        );
      }
    });
  }
  //hetphuoc

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
    return sourceCards.take(10).map((card) {
      final wrong = sourceCards
          .where((item) => item.id != card.id)
          .map((item) => item.back)
          .take(3);
      return QuizQuestion(
        prompt: card.front,
        options: [card.back, ...wrong],
        correctIndex: 0,
      );
    }).toList();
  }

  Future<TeacherQuiz> createQuiz({
    required String teacherId,
    required String setId,
    required String title,
    required int questionCount,
    required String status,
    String? assignedClassId,
  }) async {
    final db = await _db.database;
    final generatedQuestions = await generateQuiz(setId);
    final quiz = TeacherQuiz(
      id: _id('quiz'),
      teacherId: teacherId,
      setId: setId,
      title: title.trim(),
      questionCount: generatedQuestions.length,
      status: status,
      assignedClassId: status == 'published' ? assignedClassId : null,
    );
    await db.transaction((txn) async {
      await txn.insert('quizzes', quiz.toMap());
      for (var i = 0; i < generatedQuestions.length; i++) {
        final question = generatedQuestions[i];
        await txn.insert(
          'quiz_questions_demo',
          TeacherQuizQuestion(
            id: _id('quiz_question'),
            quizId: quiz.id,
            prompt: question.prompt,
            correctAnswer: question.options[question.correctIndex],
            orderIndex: i,
          ).toMap(),
        );
      }
    });
    return quiz;
  }

  Future<void> publishQuiz(String quizId, String classroomId) async {
    final db = await _db.database;
    await db.update(
      'quizzes',
      {'status': 'published', 'assigned_class_id': classroomId},
      where: 'id = ?',
      whereArgs: [quizId],
    );
  }

  Future<List<TeacherQuiz>> quizzesByTeacher(String teacherId) async {
    final db = await _db.database;
    final rows = await db.query(
      'quizzes',
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'id DESC',
    );
    return rows.map(TeacherQuiz.fromMap).toList();
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

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    required int timeLimitMinutes,
    required String questionOrder,
    required String answerOrder,
  }) async {
    final db = await _db.database;
    final questionCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM quiz_questions_demo WHERE quiz_id = ?',
            [quizId],
          ),
        ) ??
        0;
    await db.update(
      'quizzes',
      {
        'title': title.trim(),
        'time_limit_minutes': timeLimitMinutes,
        'question_order': questionOrder,
        'answer_order': answerOrder,
        'question_count': questionCount,
      },
      where: 'id = ?',
      whereArgs: [quizId],
    );
  }

  Future<void> addQuestionFromSet(String quizId) async {
    final db = await _db.database;
    final quiz = await quizById(quizId);
    if (quiz == null) return;
    final existing = await quizQuestions(quizId);
    final sourceCards = await cards(quiz.setId);
    final usedPrompts = existing.map((item) => item.prompt).toSet();
    final available = sourceCards.where(
      (card) => !usedPrompts.contains(card.front),
    );
    if (available.isEmpty) return;
    final card = available.first;
    await db.transaction((txn) async {
      await txn.insert(
        'quiz_questions_demo',
        TeacherQuizQuestion(
          id: _id('quiz_question'),
          quizId: quizId,
          prompt: card.front,
          correctAnswer: card.back,
          orderIndex: existing.length,
        ).toMap(),
      );
      await txn.update(
        'quizzes',
        {'question_count': existing.length + 1},
        where: 'id = ?',
        whereArgs: [quizId],
      );
    });
  }

  Future<void> deleteQuizQuestion(String questionId, String quizId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        'quiz_questions_demo',
        where: 'id = ?',
        whereArgs: [questionId],
      );
      final count =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM quiz_questions_demo WHERE quiz_id = ?',
              [quizId],
            ),
          ) ??
          0;
      await txn.update(
        'quizzes',
        {'question_count': count},
        where: 'id = ?',
        whereArgs: [quizId],
      );
    });
  }

  Future<void> saveQuizAttempt(
    String userId,
    String setId,
    int score,
    int total,
  ) async {
    final db = await _db.database;
    await db.insert('quiz_attempts', {
      'id': _id('attempt'),
      'user_id': userId,
      'set_id': setId,
      'score': score,
      'total': total,
    });
  }

  Future<List<Map<String, Object?>>> quizHistory(String userId) async {
    final db = await _db.database;
    return db.rawQuery(
      '''
      SELECT s.title, q.score, q.total
      FROM quiz_attempts q
      JOIN flashcard_sets s ON s.id = q.set_id
      WHERE q.user_id = ?
      ORDER BY q.id DESC
    ''',
      [userId],
    );
  }
}
