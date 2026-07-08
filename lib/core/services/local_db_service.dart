import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Quản lý SQLite local cho Flashly dựa trên sơ đồ ERD.
class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  static const _dbName = 'flashly.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _onCreate(db, version);
        await _seedData(db);
      },
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // --- 1. USER & AUTH ---
    await db.execute('''
      CREATE TABLE users (
        user_id       INTEGER PRIMARY KEY AUTOINCREMENT,
        username      TEXT NOT NULL,
        email         TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        full_name     TEXT,
        avatar        TEXT,
        phone         TEXT,
        address       TEXT,
        role          TEXT DEFAULT 'student',
        status        TEXT DEFAULT 'active',
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER NOT NULL
      )
    ''');

    // --- 2. FLASHCARD SYSTEM ---
    await db.execute('''
      CREATE TABLE flashcard_sets (
        set_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id    INTEGER NOT NULL,
        title       TEXT NOT NULL,
        description TEXT,
        visibility  TEXT DEFAULT 'public',
        is_deleted  INTEGER DEFAULT 0,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcards (
        card_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        set_id     INTEGER NOT NULL,
        front_text TEXT NOT NULL,
        back_text  TEXT NOT NULL,
        image_url  TEXT,
        hint       TEXT,
        order_no   INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (set_id) REFERENCES flashcard_sets (set_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorite_sets (
        user_id INTEGER NOT NULL,
        set_id  INTEGER NOT NULL,
        PRIMARY KEY (user_id, set_id),
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        FOREIGN KEY (set_id) REFERENCES flashcard_sets (set_id)
      )
    ''');

    // --- 3. LEARNING PROGRESS ---
    await db.execute('''
      CREATE TABLE learning_sessions (
        session_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL,
        set_id       INTEGER NOT NULL,
        status       TEXT DEFAULT 'in_progress',
        current_idx  INTEGER DEFAULT 0,
        start_time   INTEGER NOT NULL,
        end_time     INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        FOREIGN KEY (set_id) REFERENCES flashcard_sets (set_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE session_cards (
        session_card_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id      INTEGER NOT NULL,
        card_id         INTEGER NOT NULL,
        status          TEXT,
        FOREIGN KEY (session_id) REFERENCES learning_sessions (session_id) ON DELETE CASCADE,
        FOREIGN KEY (card_id) REFERENCES flashcards (card_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE card_progress (
        user_id          INTEGER NOT NULL,
        card_id          INTEGER NOT NULL,
        status           TEXT,
        review_count     INTEGER DEFAULT 0,
        last_reviewed_at INTEGER,
        PRIMARY KEY (user_id, card_id),
        FOREIGN KEY (user_id) REFERENCES users (user_id),
        FOREIGN KEY (card_id) REFERENCES flashcards (card_id)
      )
    ''');

    // --- 4. CLASSROOM & ASSIGNMENT ---
    await db.execute('''
      CREATE TABLE classrooms (
        class_id        INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id      INTEGER NOT NULL,
        name            TEXT NOT NULL,
        description     TEXT,
        join_code       TEXT UNIQUE,
        is_join_enabled INTEGER DEFAULT 1,
        is_deleted      INTEGER DEFAULT 0,
        created_at      INTEGER NOT NULL,
        updated_at      INTEGER NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE class_members (
        class_id   INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        status     TEXT DEFAULT 'active',
        joined_at  INTEGER NOT NULL,
        PRIMARY KEY (class_id, student_id),
        FOREIGN KEY (class_id) REFERENCES classrooms (class_id),
        FOREIGN KEY (student_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE assignments (
        assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id      INTEGER NOT NULL,
        set_id        INTEGER NOT NULL,
        assigned_at   INTEGER NOT NULL,
        due_at        INTEGER,
        status        TEXT DEFAULT 'active',
        FOREIGN KEY (class_id) REFERENCES classrooms (class_id),
        FOREIGN KEY (set_id) REFERENCES flashcard_sets (set_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE assignment_progress (
        assignment_id    INTEGER NOT NULL,
        student_id       INTEGER NOT NULL,
        status           TEXT DEFAULT 'not_started',
        progress_percent INTEGER DEFAULT 0,
        completed_at     INTEGER,
        updated_at       INTEGER NOT NULL,
        PRIMARY KEY (assignment_id, student_id),
        FOREIGN KEY (assignment_id) REFERENCES assignments (assignment_id),
        FOREIGN KEY (student_id) REFERENCES users (user_id)
      )
    ''');

    // --- 5. QUIZ SYSTEM ---
    await db.execute('''
      CREATE TABLE quizzes (
        quiz_id           INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id         INTEGER NOT NULL,
        title             TEXT NOT NULL,
        description       TEXT,
        time_limit_sec    INTEGER,
        question_count    INTEGER DEFAULT 0,
        shuffle_order     INTEGER DEFAULT 0,
        status            TEXT DEFAULT 'draft',
        is_deleted        INTEGER DEFAULT 0,
        created_at        INTEGER NOT NULL,
        updated_at        INTEGER NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES users (user_id)
      )
    ''');

    // Bảng nối: một Quiz có thể được biên soạn ("built_from") từ một hoặc
    // nhiều FlashcardSet làm nguồn câu hỏi (quan hệ used_in / built_from
    // trong ERD giữa Quiz và FlashcardSet).
    await db.execute('''
      CREATE TABLE quiz_sources (
        quiz_id    INTEGER NOT NULL,
        set_id     INTEGER NOT NULL,
        PRIMARY KEY (quiz_id, set_id),
        FOREIGN KEY (quiz_id) REFERENCES quizzes (quiz_id) ON DELETE CASCADE,
        FOREIGN KEY (set_id) REFERENCES flashcard_sets (set_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_questions (
        question_id   INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id       INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        question_type TEXT,
        image_url     TEXT,
        position      INTEGER DEFAULT 0,
        FOREIGN KEY (quiz_id) REFERENCES quizzes (quiz_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_options (
        option_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id  INTEGER NOT NULL,
        option_text  TEXT NOT NULL,
        is_correct   INTEGER DEFAULT 0,
        display_order INTEGER DEFAULT 0,
        FOREIGN KEY (question_id) REFERENCES quiz_questions (question_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_assignments (
        quiz_assign_id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id        INTEGER NOT NULL,
        class_id       INTEGER NOT NULL,
        assigned_at    INTEGER NOT NULL,
        due_at         INTEGER,
        status         TEXT DEFAULT 'active',
        FOREIGN KEY (quiz_id) REFERENCES quizzes (quiz_id),
        FOREIGN KEY (class_id) REFERENCES classrooms (class_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_attempts (
        attempt_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_assign_id  INTEGER NOT NULL,
        student_id      INTEGER NOT NULL,
        score           REAL DEFAULT 0.0,
        total_questions INTEGER DEFAULT 0,
        started_at      INTEGER NOT NULL,
        completed_at    INTEGER,
        duration_sec    INTEGER,
        FOREIGN KEY (quiz_assign_id) REFERENCES quiz_assignments (quiz_assign_id),
        FOREIGN KEY (student_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_answers (
        answer_id      INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id     INTEGER NOT NULL,
        question_id    INTEGER NOT NULL,
        selected_opt_id INTEGER,
        is_correct     INTEGER DEFAULT 0,
        answered_at    INTEGER NOT NULL,
        FOREIGN KEY (attempt_id) REFERENCES quiz_attempts (attempt_id) ON DELETE CASCADE,
        FOREIGN KEY (question_id) REFERENCES quiz_questions (question_id),
        FOREIGN KEY (selected_opt_id) REFERENCES quiz_options (option_id)
      )
    ''');

    // --- 6. ACTIVITIES ---
    await db.execute('''
      CREATE TABLE class_activities (
        activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id    INTEGER NOT NULL,
        actor_id    INTEGER NOT NULL,
        type        TEXT NOT NULL,
        target_id   INTEGER,
        content     TEXT,
        created_at  INTEGER NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classrooms (class_id) ON DELETE CASCADE,
        FOREIGN KEY (actor_id) REFERENCES users (user_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_flashcards_set ON flashcards(set_id)');
    await db.execute('CREATE INDEX idx_questions_quiz ON quiz_questions(quiz_id)');
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Users (4 rows: Admin, Teacher, 2 Students)
    await db.insert('users', {
      'user_id': 1, 'username': 'admin', 'email': 'admin@flashly.com', 'password_hash': 'admin123',
      'full_name': 'Flashly Admin', 'role': 'admin', 'created_at': now, 'updated_at': now
    });
    await db.insert('users', {
      'user_id': 2, 'username': 'gv_nam', 'email': 'nam.nguyen@edu.vn', 'password_hash': 'teacher123',
      'full_name': 'Nguyễn Văn Nam', 'role': 'teacher', 'created_at': now, 'updated_at': now
    });
    await db.insert('users', {
      'user_id': 3, 'username': 'sv_an', 'email': 'an.le@student.com', 'password_hash': 'student123',
      'full_name': 'Lê Thị An', 'role': 'student', 'created_at': now, 'updated_at': now
    });
    await db.insert('users', {
      'user_id': 4, 'username': 'sv_binh', 'email': 'binh.tran@student.com', 'password_hash': 'student123',
      'full_name': 'Trần Thanh Bình', 'role': 'student', 'created_at': now, 'updated_at': now
    });

    // 2. Flashcard Sets (4 rows)
    await db.insert('flashcard_sets', {
      'set_id': 1, 'owner_id': 2, 'title': 'IELTS Vocabulary - Unit 1', 'description': 'Chủ đề Education',
      'visibility': 'public', 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcard_sets', {
      'set_id': 2, 'owner_id': 2, 'title': 'Flutter Architecture', 'description': 'Clean Architecture & Riverpod',
      'visibility': 'public', 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcard_sets', {
      'set_id': 3, 'owner_id': 3, 'title': 'Vật lý 12 - Sóng cơ', 'description': 'Công thức quan trọng',
      'visibility': 'private', 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcard_sets', {
      'set_id': 4, 'owner_id': 4, 'title': 'JLPT N3 Kanji', 'description': '100 chữ Kanji Unit 1',
      'visibility': 'public', 'created_at': now, 'updated_at': now
    });

    // 3. Flashcards (4 rows for Set 1)
    await db.insert('flashcards', {
      'card_id': 1, 'set_id': 1, 'front_text': 'Pedagogy', 'back_text': 'Khoa học sư phạm',
      'hint': 'Starts with P', 'order_no': 1, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 2, 'set_id': 1, 'front_text': 'Curriculum', 'back_text': 'Chương trình giảng dạy',
      'order_no': 2, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 3, 'set_id': 1, 'front_text': 'Distance Learning', 'back_text': 'Học từ xa',
      'order_no': 3, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 4, 'set_id': 1, 'front_text': 'Vocational School', 'back_text': 'Trường nghề',
      'order_no': 4, 'created_at': now, 'updated_at': now
    });
    // Thêm thẻ cho các bộ set 2, 3, 4 để các bảng phụ thuộc phía sau
    // (learning_sessions, session_cards, card_progress...) có dữ liệu tham chiếu.
    await db.insert('flashcards', {
      'card_id': 5, 'set_id': 2, 'front_text': 'Riverpod', 'back_text': 'Thư viện quản lý state cho Flutter',
      'order_no': 1, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 6, 'set_id': 2, 'front_text': 'Clean Architecture', 'back_text': 'Kiến trúc phân lớp: domain - data - presentation',
      'order_no': 2, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 7, 'set_id': 3, 'front_text': 'Bước sóng (λ)', 'back_text': 'Khoảng cách giữa 2 điểm dao động cùng pha gần nhau nhất',
      'order_no': 1, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 8, 'set_id': 3, 'front_text': 'Tần số (f)', 'back_text': 'Số dao động trong 1 giây, đơn vị Hz',
      'order_no': 2, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 9, 'set_id': 4, 'front_text': '学', 'back_text': 'Học (がく/まな)',
      'order_no': 1, 'created_at': now, 'updated_at': now
    });
    await db.insert('flashcards', {
      'card_id': 10, 'set_id': 4, 'front_text': '校', 'back_text': 'Trường (こう)',
      'order_no': 2, 'created_at': now, 'updated_at': now
    });

    // 4. Classrooms (4 rows)
    await db.insert('classrooms', {
      'class_id': 1, 'teacher_id': 2, 'name': 'Lớp Anh Văn 12A1', 'join_code': 'AV12A1',
      'created_at': now, 'updated_at': now
    });
    await db.insert('classrooms', {
      'class_id': 2, 'teacher_id': 2, 'name': 'Lớp Lập trình Mobile', 'join_code': 'MOB2024',
      'created_at': now, 'updated_at': now
    });
    await db.insert('classrooms', {
      'class_id': 3, 'teacher_id': 2, 'name': 'Lớp Kỹ năng mềm', 'join_code': 'SOFT01',
      'created_at': now, 'updated_at': now
    });
    await db.insert('classrooms', {
      'class_id': 4, 'teacher_id': 2, 'name': 'Lớp Tiếng Nhật N3', 'join_code': 'JPN3',
      'created_at': now, 'updated_at': now
    });

    // 5. Quizzes (4 rows)
    await db.insert('quizzes', {
      'quiz_id': 1, 'teacher_id': 2, 'title': 'Kiểm tra từ vựng IELTS', 'question_count': 10,
      'status': 'published', 'created_at': now, 'updated_at': now
    });
    await db.insert('quizzes', {
      'quiz_id': 2, 'teacher_id': 2, 'title': 'Quiz Flutter Basic', 'question_count': 5,
      'status': 'published', 'created_at': now, 'updated_at': now
    });
    await db.insert('quizzes', {
      'quiz_id': 3, 'teacher_id': 2, 'title': 'Kiểm tra Vật lý 12', 'question_count': 20,
      'status': 'draft', 'created_at': now, 'updated_at': now
    });
    await db.insert('quizzes', {
      'quiz_id': 4, 'teacher_id': 2, 'title': 'Final Kanji N3', 'question_count': 50,
      'status': 'published', 'created_at': now, 'updated_at': now
    });

    // 6. Favorite Sets
    await db.insert('favorite_sets', {'user_id': 3, 'set_id': 1});
    await db.insert('favorite_sets', {'user_id': 3, 'set_id': 4});
    await db.insert('favorite_sets', {'user_id': 4, 'set_id': 1});
    await db.insert('favorite_sets', {'user_id': 4, 'set_id': 2});

    // 7. Class Members
    await db.insert('class_members', {'class_id': 1, 'student_id': 3, 'joined_at': now});
    await db.insert('class_members', {'class_id': 1, 'student_id': 4, 'joined_at': now});
    await db.insert('class_members', {'class_id': 2, 'student_id': 3, 'joined_at': now});
    await db.insert('class_members', {'class_id': 4, 'student_id': 4, 'joined_at': now});

    // 8. Quiz Sources (Quiz được biên soạn "built_from" FlashcardSet nào)
    await db.insert('quiz_sources', {'quiz_id': 1, 'set_id': 1});
    await db.insert('quiz_sources', {'quiz_id': 2, 'set_id': 2});
    await db.insert('quiz_sources', {'quiz_id': 3, 'set_id': 3});
    await db.insert('quiz_sources', {'quiz_id': 4, 'set_id': 4});

    // 9. Assignments (giao bộ thẻ cho lớp)
    await db.insert('assignments', {
      'assignment_id': 1, 'class_id': 1, 'set_id': 1,
      'assigned_at': now, 'due_at': now + 7 * 86400000, 'status': 'active'
    });
    await db.insert('assignments', {
      'assignment_id': 2, 'class_id': 2, 'set_id': 2,
      'assigned_at': now, 'due_at': now + 10 * 86400000, 'status': 'active'
    });
    await db.insert('assignments', {
      'assignment_id': 3, 'class_id': 3, 'set_id': 1,
      'assigned_at': now, 'due_at': now + 5 * 86400000, 'status': 'active'
    });
    await db.insert('assignments', {
      'assignment_id': 4, 'class_id': 4, 'set_id': 4,
      'assigned_at': now, 'due_at': now + 14 * 86400000, 'status': 'active'
    });

    // 10. Assignment Progress (theo dõi tiến độ học sinh với assignment)
    await db.insert('assignment_progress', {
      'assignment_id': 1, 'student_id': 3, 'status': 'completed',
      'progress_percent': 100, 'completed_at': now, 'updated_at': now
    });
    await db.insert('assignment_progress', {
      'assignment_id': 1, 'student_id': 4, 'status': 'in_progress',
      'progress_percent': 50, 'updated_at': now
    });
    await db.insert('assignment_progress', {
      'assignment_id': 2, 'student_id': 3, 'status': 'not_started',
      'progress_percent': 0, 'updated_at': now
    });
    await db.insert('assignment_progress', {
      'assignment_id': 4, 'student_id': 4, 'status': 'in_progress',
      'progress_percent': 30, 'updated_at': now
    });

    // 11. Learning Sessions (phiên học flashcard)
    await db.insert('learning_sessions', {
      'session_id': 1, 'user_id': 3, 'set_id': 1, 'status': 'completed',
      'current_idx': 4, 'start_time': now - 3600000, 'end_time': now
    });
    await db.insert('learning_sessions', {
      'session_id': 2, 'user_id': 3, 'set_id': 4, 'status': 'in_progress',
      'current_idx': 1, 'start_time': now
    });
    await db.insert('learning_sessions', {
      'session_id': 3, 'user_id': 4, 'set_id': 1, 'status': 'completed',
      'current_idx': 4, 'start_time': now - 7200000, 'end_time': now - 3600000
    });
    await db.insert('learning_sessions', {
      'session_id': 4, 'user_id': 4, 'set_id': 2, 'status': 'in_progress',
      'current_idx': 1, 'start_time': now
    });

    // 12. Session Cards (từng thẻ đã hiện ra trong 1 phiên học)
    await db.insert('session_cards', {'session_id': 1, 'card_id': 1, 'status': 'known'});
    await db.insert('session_cards', {'session_id': 1, 'card_id': 2, 'status': 'unknown'});
    await db.insert('session_cards', {'session_id': 2, 'card_id': 9, 'status': 'known'});
    await db.insert('session_cards', {'session_id': 4, 'card_id': 5, 'status': 'known'});

    // 13. Card Progress (mức độ ghi nhớ từng thẻ của từng user)
    await db.insert('card_progress', {
      'user_id': 3, 'card_id': 1, 'status': 'known', 'review_count': 3, 'last_reviewed_at': now
    });
    await db.insert('card_progress', {
      'user_id': 3, 'card_id': 9, 'status': 'known', 'review_count': 1, 'last_reviewed_at': now
    });
    await db.insert('card_progress', {
      'user_id': 4, 'card_id': 1, 'status': 'unknown', 'review_count': 1, 'last_reviewed_at': now
    });
    await db.insert('card_progress', {
      'user_id': 4, 'card_id': 5, 'status': 'known', 'review_count': 2, 'last_reviewed_at': now
    });

    // 14. Quiz Questions
    await db.insert('quiz_questions', {
      'question_id': 1, 'quiz_id': 1, 'question_text': "'Pedagogy' nghĩa là gì?",
      'question_type': 'single_choice', 'position': 1
    });
    await db.insert('quiz_questions', {
      'question_id': 2, 'quiz_id': 1, 'question_text': "'Curriculum' nghĩa là gì?",
      'question_type': 'single_choice', 'position': 2
    });
    await db.insert('quiz_questions', {
      'question_id': 3, 'quiz_id': 2, 'question_text': 'StatefulWidget khác StatelessWidget ở điểm nào?',
      'question_type': 'single_choice', 'position': 1
    });
    await db.insert('quiz_questions', {
      'question_id': 4, 'quiz_id': 4, 'question_text': "Chữ Kanji '学' nghĩa là gì?",
      'question_type': 'single_choice', 'position': 1
    });

    // 15. Quiz Options
    await db.insert('quiz_options', {
      'option_id': 1, 'question_id': 1, 'option_text': 'Khoa học sư phạm', 'is_correct': 1, 'display_order': 1
    });
    await db.insert('quiz_options', {
      'option_id': 2, 'question_id': 1, 'option_text': 'Địa lý học', 'is_correct': 0, 'display_order': 2
    });
    await db.insert('quiz_options', {
      'option_id': 3, 'question_id': 2, 'option_text': 'Chương trình giảng dạy', 'is_correct': 1, 'display_order': 1
    });
    await db.insert('quiz_options', {
      'option_id': 4, 'question_id': 2, 'option_text': 'Kỳ thi tốt nghiệp', 'is_correct': 0, 'display_order': 2
    });
    await db.insert('quiz_options', {
      'option_id': 5, 'question_id': 3,
      'option_text': 'StatefulWidget có thể thay đổi trạng thái, StatelessWidget thì không',
      'is_correct': 1, 'display_order': 1
    });
    await db.insert('quiz_options', {
      'option_id': 6, 'question_id': 3, 'option_text': 'Không có gì khác biệt', 'is_correct': 0, 'display_order': 2
    });
    await db.insert('quiz_options', {
      'option_id': 7, 'question_id': 4, 'option_text': 'Học', 'is_correct': 1, 'display_order': 1
    });
    await db.insert('quiz_options', {
      'option_id': 8, 'question_id': 4, 'option_text': 'Chơi', 'is_correct': 0, 'display_order': 2
    });

    // 16. Quiz Assignments (giao quiz cho lớp)
    await db.insert('quiz_assignments', {
      'quiz_assign_id': 1, 'quiz_id': 1, 'class_id': 1,
      'assigned_at': now, 'due_at': now + 7 * 86400000, 'status': 'active'
    });
    await db.insert('quiz_assignments', {
      'quiz_assign_id': 2, 'quiz_id': 2, 'class_id': 2,
      'assigned_at': now, 'due_at': now + 7 * 86400000, 'status': 'active'
    });
    await db.insert('quiz_assignments', {
      'quiz_assign_id': 3, 'quiz_id': 4, 'class_id': 4,
      'assigned_at': now, 'due_at': now + 7 * 86400000, 'status': 'active'
    });
    await db.insert('quiz_assignments', {
      'quiz_assign_id': 4, 'quiz_id': 1, 'class_id': 3,
      'assigned_at': now, 'due_at': now + 7 * 86400000, 'status': 'active'
    });

    // 17. Quiz Attempts (học sinh làm bài)
    await db.insert('quiz_attempts', {
      'attempt_id': 1, 'quiz_assign_id': 1, 'student_id': 3, 'score': 5.0,
      'total_questions': 2, 'started_at': now - 600000, 'completed_at': now, 'duration_sec': 600
    });
    await db.insert('quiz_attempts', {
      'attempt_id': 2, 'quiz_assign_id': 1, 'student_id': 4, 'score': 2.5,
      'total_questions': 2, 'started_at': now - 500000, 'completed_at': now, 'duration_sec': 500
    });
    await db.insert('quiz_attempts', {
      'attempt_id': 3, 'quiz_assign_id': 2, 'student_id': 3, 'score': 10.0,
      'total_questions': 1, 'started_at': now - 300000, 'completed_at': now, 'duration_sec': 300
    });
    await db.insert('quiz_attempts', {
      'attempt_id': 4, 'quiz_assign_id': 3, 'student_id': 4, 'score': 10.0,
      'total_questions': 1, 'started_at': now - 200000, 'completed_at': now, 'duration_sec': 200
    });

    // 18. Quiz Answers (đáp án học sinh đã chọn)
    await db.insert('quiz_answers', {
      'answer_id': 1, 'attempt_id': 1, 'question_id': 1, 'selected_opt_id': 1,
      'is_correct': 1, 'answered_at': now
    });
    await db.insert('quiz_answers', {
      'answer_id': 2, 'attempt_id': 1, 'question_id': 2, 'selected_opt_id': 4,
      'is_correct': 0, 'answered_at': now
    });
    await db.insert('quiz_answers', {
      'answer_id': 3, 'attempt_id': 2, 'question_id': 1, 'selected_opt_id': 1,
      'is_correct': 1, 'answered_at': now
    });
    await db.insert('quiz_answers', {
      'answer_id': 4, 'attempt_id': 3, 'question_id': 3, 'selected_opt_id': 5,
      'is_correct': 1, 'answered_at': now
    });
    await db.insert('quiz_answers', {
      'answer_id': 5, 'attempt_id': 4, 'question_id': 4, 'selected_opt_id': 7,
      'is_correct': 1, 'answered_at': now
    });

    // 19. Class Activities (nhật ký hoạt động của lớp)
    await db.insert('class_activities', {
      'activity_id': 1, 'class_id': 1, 'actor_id': 2, 'type': 'create_assignment',
      'target_id': 1, 'content': 'Giáo viên đã giao bộ thẻ "IELTS Vocabulary - Unit 1"', 'created_at': now
    });
    await db.insert('class_activities', {
      'activity_id': 2, 'class_id': 1, 'actor_id': 3, 'type': 'join_class',
      'content': 'Lê Thị An đã tham gia lớp', 'created_at': now
    });
    await db.insert('class_activities', {
      'activity_id': 3, 'class_id': 2, 'actor_id': 2, 'type': 'create_quiz',
      'target_id': 2, 'content': 'Giáo viên đã tạo Quiz "Flutter Basic"', 'created_at': now
    });
    await db.insert('class_activities', {
      'activity_id': 4, 'class_id': 4, 'actor_id': 4, 'type': 'join_class',
      'content': 'Trần Thanh Bình đã tham gia lớp', 'created_at': now
    });
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {}

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> wipe() async {
    final db = await database;
    await db.transaction((txn) async {
      final tables = [
        'users', 'flashcard_sets', 'flashcards', 'favorite_sets',
        'learning_sessions', 'session_cards', 'card_progress',
        'classrooms', 'class_members', 'assignments', 'assignment_progress',
        'quizzes', 'quiz_sources', 'quiz_questions', 'quiz_options', 'quiz_assignments',
        'quiz_attempts', 'quiz_answers', 'class_activities'
      ];
      for (var table in tables) {
        await txn.delete(table);
      }
    });
  }
}