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
        description: 'Lớp demo học thuật ngữ và từ vựng',
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

      final now = DateTime.now();
      await txn.insert('assigned_sets', {
        'id': 'assign_demo_ielts',
        'class_id': classroom.id,
        'set_id': 'set_ielts_vocab',
        'assigned_by_id': 'demo_teacher',
        'due_at': now.add(const Duration(days: 5)).toIso8601String(),
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      });
      await txn.insert('class_activities', {
        'id': 'act_demo_1',
        'class_id': classroom.id,
        'user_id': 'demo_teacher',
        'action': 'assign_set',
        'target_id': 'assign_demo_ielts',
        'message': "đã giao 'Từ vựng IELTS cơ bản'",
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
      });
      await txn.insert('class_activities', {
        'id': 'act_demo_2',
        'class_id': classroom.id,
        'user_id': 'demo_student',
        'action': 'join',
        'target_id': null,
        'message': 'đã tham gia lớp',
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
      });
    });
  }

  /// Seeds classroom extras when DB already existed before Feature 4 tables.
  Future<void> ensureClassroomExtras() async {
    final db = await _db.database;
    final assigned = await db.query('assigned_sets', limit: 1);
    if (assigned.isNotEmpty) return;
    final classRows = await db.query(
      'classrooms',
      where: 'id = ?',
      whereArgs: ['class_demo_10a1'],
      limit: 1,
    );
    if (classRows.isEmpty) return;

    final now = DateTime.now();
    await db.insert('assigned_sets', {
      'id': 'assign_demo_ielts',
      'class_id': 'class_demo_10a1',
      'set_id': 'set_ielts_vocab',
      'assigned_by_id': 'demo_teacher',
      'due_at': now.add(const Duration(days: 5)).toIso8601String(),
      'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('class_activities', {
      'id': 'act_demo_1',
      'class_id': 'class_demo_10a1',
      'user_id': 'demo_teacher',
      'action': 'assign_set',
      'target_id': 'assign_demo_ielts',
      'message': "đã giao 'Từ vựng IELTS cơ bản'",
      'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('class_activities', {
      'id': 'act_demo_2',
      'class_id': 'class_demo_10a1',
      'user_id': 'demo_student',
      'action': 'join',
      'target_id': null,
      'message': 'đã tham gia lớp',
      'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
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
      joinCode: await _generateUniqueJoinCode(db),
      isJoinEnabled: true,
    );
    await db.insert('classrooms', classroom.toMap());
    await db.insert('class_members', {
      'class_id': classroom.id,
      'user_id': teacherId,
      'role': 'teacher',
    });
    await _logActivity(
      classId: classroom.id,
      userId: teacherId,
      action: 'create_class',
      message: 'đã tạo lớp học',
    );
    return classroom;
  }

  Future<List<Classroom>> classrooms(String userId) async {
    final db = await _db.database;
    await ensureClassroomExtras();
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

  Future<Classroom?> classroomById(String classId) async {
    final db = await _db.database;
    final rows = await db.query(
      'classrooms',
      where: 'id = ?',
      whereArgs: [classId],
      limit: 1,
    );
    return rows.isEmpty ? null : Classroom.fromMap(rows.first);
  }

  Future<ClassroomPreview?> previewJoinByCode(String joinCode) async {
    final db = await _db.database;
    final rows = await db.query(
      'classrooms',
      where: 'join_code = ? AND is_join_enabled = 1',
      whereArgs: [joinCode.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final classroom = Classroom.fromMap(rows.first);
    return _previewForClassroom(classroom);
  }

  Future<ClassroomPreview?> classroomPreview(String classId) async {
    final classroom = await classroomById(classId);
    if (classroom == null) return null;
    return _previewForClassroom(classroom);
  }

  Future<ClassroomPreview> _previewForClassroom(Classroom classroom) async {
    final teacher = await userById(classroom.teacherId);
    final studentCount = await memberCount(classroom.id, role: 'student');
    final setCount = await assignedSetCount(classroom.id);
    return ClassroomPreview(
      classroom: classroom,
      teacherName: teacher?.fullName.isNotEmpty == true
          ? teacher!.fullName
          : (teacher?.username ?? 'Giáo viên'),
      studentCount: studentCount,
      setCount: setCount,
    );
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
    await _logActivity(
      classId: classroom.id,
      userId: userId,
      action: 'join',
      message: 'đã tham gia lớp',
    );
    return classroom;
  }

  Future<void> updateClass({
    required String classId,
    required String name,
    String description = '',
  }) async {
    final db = await _db.database;
    await db.update(
      'classrooms',
      {'name': name.trim(), 'description': description.trim()},
      where: 'id = ?',
      whereArgs: [classId],
    );
  }

  Future<void> deleteClass(String classId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final assigned = await txn.query(
        'assigned_sets',
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      for (final row in assigned) {
        final assignedId = row['id'] as String;
        await txn.delete(
          'assignment_progress',
          where: 'assigned_set_id = ?',
          whereArgs: [assignedId],
        );
      }
      await txn.delete(
        'assigned_sets',
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      await txn.delete(
        'class_activities',
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      await txn.delete(
        'class_members',
        where: 'class_id = ?',
        whereArgs: [classId],
      );
      await txn.delete('classrooms', where: 'id = ?', whereArgs: [classId]);
    });
  }

  Future<String> regenerateJoinCode(String classId) async {
    final db = await _db.database;
    final code = await _generateUniqueJoinCode(db);
    await db.update(
      'classrooms',
      {'join_code': code},
      where: 'id = ?',
      whereArgs: [classId],
    );
    return code;
  }

  Future<void> setJoinEnabled(String classId, bool enabled) async {
    final db = await _db.database;
    await db.update(
      'classrooms',
      {'is_join_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [classId],
    );
  }

  Future<List<ClassMember>> membersOf(String classId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT u.id, u.username, u.email, u.full_name, m.role
      FROM class_members m
      JOIN users u ON u.id = m.user_id
      WHERE m.class_id = ?
      ORDER BY m.role DESC, u.full_name, u.username
    ''',
      [classId],
    );
    return rows
        .map(
          (row) => ClassMember(
            userId: row['id'] as String,
            username: row['username'] as String,
            email: row['email'] as String,
            fullName: (row['full_name'] as String?) ?? '',
            role: row['role'] as String,
          ),
        )
        .toList();
  }

  Future<int> memberCount(String classId, {String? role}) async {
    final db = await _db.database;
    if (role == null) {
      return Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM class_members WHERE class_id = ?',
              [classId],
            ),
          ) ??
          0;
    }
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM class_members WHERE class_id = ? AND role = ?',
            [classId, role],
          ),
        ) ??
        0;
  }

  Future<void> addMemberByEmail({
    required String classId,
    required String email,
    required String actorId,
  }) async {
    final db = await _db.database;
    final users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim()],
      limit: 1,
    );
    if (users.isEmpty) {
      throw Exception('Không tìm thấy người dùng với email này');
    }
    final user = AppUser.fromMap(users.first);
    await db.insert('class_members', {
      'class_id': classId,
      'user_id': user.id,
      'role': 'student',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await _logActivity(
      classId: classId,
      userId: actorId,
      action: 'add_member',
      targetId: user.id,
      message: 'đã thêm ${user.fullName.isNotEmpty ? user.fullName : user.username}',
    );
  }

  Future<void> removeMember({
    required String classId,
    required String userId,
    required String actorId,
  }) async {
    final db = await _db.database;
    final classroom = await classroomById(classId);
    if (classroom != null && classroom.teacherId == userId) {
      throw Exception('Không thể xóa giáo viên phụ trách lớp');
    }
    await db.delete(
      'class_members',
      where: 'class_id = ? AND user_id = ?',
      whereArgs: [classId, userId],
    );
    await _logActivity(
      classId: classId,
      userId: actorId,
      action: 'remove_member',
      targetId: userId,
      message: 'đã xóa một thành viên khỏi lớp',
    );
  }

  Future<void> leaveClass({
    required String classId,
    required String userId,
  }) async {
    final db = await _db.database;
    final classroom = await classroomById(classId);
    if (classroom != null && classroom.teacherId == userId) {
      throw Exception('Giáo viên không thể rời lớp. Hãy xóa lớp nếu cần.');
    }
    await db.delete(
      'class_members',
      where: 'class_id = ? AND user_id = ?',
      whereArgs: [classId, userId],
    );
    await _logActivity(
      classId: classId,
      userId: userId,
      action: 'leave',
      message: 'đã rời lớp',
    );
  }

  Future<int> assignedSetCount(String classId) async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM assigned_sets WHERE class_id = ?',
            [classId],
          ),
        ) ??
        0;
  }

  Future<List<AssignedSetItem>> assignedSetsForClass(String classId) async {
    final db = await _db.database;
    await ensureClassroomExtras();
    final studentCount = await memberCount(classId, role: 'student');
    final rows = await db.rawQuery(
      '''
      SELECT a.id, a.class_id, a.set_id, a.assigned_by_id, a.due_at, a.created_at,
             s.title AS set_title, s.card_count,
             (SELECT COUNT(*) FROM assignment_progress p
              WHERE p.assigned_set_id = a.id) AS completed_count
      FROM assigned_sets a
      JOIN flashcard_sets s ON s.id = a.set_id
      WHERE a.class_id = ?
      ORDER BY a.created_at DESC
    ''',
      [classId],
    );
    return rows
        .map(
          (row) => AssignedSetItem(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            setId: row['set_id'] as String,
            setTitle: row['set_title'] as String,
            cardCount: (row['card_count'] as int?) ?? 0,
            assignedById: row['assigned_by_id'] as String,
            dueAt: row['due_at'] as String?,
            createdAt: row['created_at'] as String,
            completedCount: (row['completed_count'] as int?) ?? 0,
            studentCount: studentCount,
          ),
        )
        .toList();
  }

  Future<AssignedSetItem> assignSet({
    required String classId,
    required String setId,
    required String assignedById,
    DateTime? dueAt,
  }) async {
    final db = await _db.database;
    final setRows = await db.query(
      'flashcard_sets',
      where: 'id = ?',
      whereArgs: [setId],
      limit: 1,
    );
    if (setRows.isEmpty) {
      throw Exception('Không tìm thấy bộ thẻ');
    }
    final set = FlashcardSet.fromMap(setRows.first);
    final assignedId = _id('assign');
    final createdAt = DateTime.now().toIso8601String();
    await db.insert('assigned_sets', {
      'id': assignedId,
      'class_id': classId,
      'set_id': setId,
      'assigned_by_id': assignedById,
      'due_at': dueAt?.toIso8601String(),
      'created_at': createdAt,
    });
    await _logActivity(
      classId: classId,
      userId: assignedById,
      action: 'assign_set',
      targetId: assignedId,
      message: "đã giao '${set.title}'",
    );
    final studentCount = await memberCount(classId, role: 'student');
    return AssignedSetItem(
      id: assignedId,
      classId: classId,
      setId: setId,
      setTitle: set.title,
      cardCount: set.cardCount,
      assignedById: assignedById,
      dueAt: dueAt?.toIso8601String(),
      createdAt: createdAt,
      completedCount: 0,
      studentCount: studentCount,
    );
  }

  Future<void> unassignSet(String assignedSetId, String actorId) async {
    final db = await _db.database;
    final rows = await db.query(
      'assigned_sets',
      where: 'id = ?',
      whereArgs: [assignedSetId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final classId = rows.first['class_id'] as String;
    await db.transaction((txn) async {
      await txn.delete(
        'assignment_progress',
        where: 'assigned_set_id = ?',
        whereArgs: [assignedSetId],
      );
      await txn.delete(
        'assigned_sets',
        where: 'id = ?',
        whereArgs: [assignedSetId],
      );
    });
    await _logActivity(
      classId: classId,
      userId: actorId,
      action: 'unassign_set',
      targetId: assignedSetId,
      message: 'đã gỡ một bộ thẻ đã giao',
    );
  }

  Future<List<ClassActivity>> activitiesForClass(String classId) async {
    final db = await _db.database;
    await ensureClassroomExtras();
    final rows = await db.rawQuery(
      '''
      SELECT a.*, u.full_name, u.username
      FROM class_activities a
      JOIN users u ON u.id = a.user_id
      WHERE a.class_id = ?
      ORDER BY a.timestamp DESC
      LIMIT 50
    ''',
      [classId],
    );
    return rows
        .map(
          (row) => ClassActivity(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            userId: row['user_id'] as String,
            action: row['action'] as String,
            targetId: row['target_id'] as String?,
            message: (row['message'] as String?) ?? '',
            timestamp: row['timestamp'] as String,
            actorName: ((row['full_name'] as String?)?.isNotEmpty == true)
                ? row['full_name'] as String
                : (row['username'] as String? ?? ''),
          ),
        )
        .toList();
  }

  Future<double> classCompletionRate(String classId) async {
    final items = await assignedSetsForClass(classId);
    if (items.isEmpty) return 0;
    final totalRatio = items.fold<double>(
      0,
      (sum, item) => sum + item.progressRatio,
    );
    return totalRatio / items.length;
  }

  Future<String> _generateUniqueJoinCode(Database db) async {
    final random = Random();
    for (var i = 0; i < 20; i++) {
      final code = (100000 + random.nextInt(900000)).toString();
      final existing = await db.query(
        'classrooms',
        where: 'join_code = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (existing.isEmpty) return code;
    }
    return DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  }

  Future<void> markAssignmentCompleted({
    required String assignedSetId,
    required String userId,
    required String classId,
  }) async {
    final db = await _db.database;
    await db.insert('assignment_progress', {
      'id': _id('progress'),
      'assigned_set_id': assignedSetId,
      'user_id': userId,
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _logActivity(
      classId: classId,
      userId: userId,
      action: 'complete_set',
      targetId: assignedSetId,
      message: 'đã hoàn thành một bộ thẻ được giao',
    );
  }

  Future<bool> hasCompletedAssignment({
    required String assignedSetId,
    required String userId,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'assignment_progress',
      where: 'assigned_set_id = ? AND user_id = ?',
      whereArgs: [assignedSetId, userId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _logActivity({
    required String classId,
    required String userId,
    required String action,
    String? targetId,
    String message = '',
  }) async {
    final db = await _db.database;
    await db.insert('class_activities', {
      'id': _id('act'),
      'class_id': classId,
      'user_id': userId,
      'action': action,
      'target_id': targetId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
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
