PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  user_id       INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid  TEXT NOT NULL UNIQUE,
  email         TEXT NOT NULL UNIQUE,
  full_name     TEXT,
  role          TEXT NOT NULL DEFAULT 'student'
                CHECK (role IN ('student', 'teacher', 'admin')),
  status        TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'locked', 'disabled')),
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS quizzes (
  quiz_id           INTEGER PRIMARY KEY AUTOINCREMENT,
  teacher_id        INTEGER NOT NULL,
  title             TEXT NOT NULL,
  description       TEXT,
  time_limit_sec    INTEGER,
  question_count    INTEGER NOT NULL DEFAULT 0,
  shuffle_order     INTEGER NOT NULL DEFAULT 0,
  status            TEXT NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft', 'published', 'closed')),
  is_deleted        INTEGER NOT NULL DEFAULT 0,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL,
  FOREIGN KEY (teacher_id) REFERENCES users (user_id)
);

CREATE TABLE IF NOT EXISTS quiz_questions (
  question_id       INTEGER PRIMARY KEY AUTOINCREMENT,
  quiz_id           INTEGER NOT NULL,
  question_text     TEXT NOT NULL,
  question_type     TEXT NOT NULL DEFAULT 'multiple_choice',
  image_url         TEXT,
  position          INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (quiz_id) REFERENCES quizzes (quiz_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS quiz_options (
  option_id         INTEGER PRIMARY KEY AUTOINCREMENT,
  question_id       INTEGER NOT NULL,
  option_text       TEXT NOT NULL,
  is_correct        INTEGER NOT NULL DEFAULT 0,
  display_order     INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (question_id) REFERENCES quiz_questions (question_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_quizzes_teacher
  ON quizzes (teacher_id, is_deleted, updated_at);
CREATE INDEX IF NOT EXISTS idx_quizzes_status
  ON quizzes (status, is_deleted, updated_at);
CREATE INDEX IF NOT EXISTS idx_quiz_questions_quiz
  ON quiz_questions (quiz_id, position);

-- Tài khoản chỉ dành cho chế độ FIREBASE_DEV_AUTH=true khi chạy local.
INSERT OR IGNORE INTO users (
  user_id, firebase_uid, email, full_name, role, status, created_at, updated_at
) VALUES
  (1, 'dev-teacher', 'teacher@flashly.local', 'Giáo viên Demo',
   'teacher', 'active', 0, 0),
  (2, 'dev-student', 'student@flashly.local', 'Học sinh Demo',
   'student', 'active', 0, 0);

INSERT OR IGNORE INTO quizzes (
  quiz_id, teacher_id, title, description, time_limit_sec, question_count,
  shuffle_order, status, is_deleted, created_at, updated_at
) VALUES
  (1, 1, 'Quiz Flutter Basic', 'Quiz mẫu từ Dart backend', 600, 5,
   1, 'published', 0, 0, 0),
  (2, 1, 'Bản nháp kiểm tra từ vựng', NULL, 900, 10,
   0, 'draft', 0, 0, 0);
