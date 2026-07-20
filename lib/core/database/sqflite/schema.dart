const createUsersTable = '''
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  email TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  role TEXT NOT NULL,
  status TEXT NOT NULL,
  avatar_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createFlashcardSetsTable = '''
CREATE TABLE IF NOT EXISTS flashcard_sets (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  owner_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  visibility TEXT NOT NULL,
  card_count INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createFlashcardsTable = '''
CREATE TABLE IF NOT EXISTS flashcards (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  set_id TEXT NOT NULL REFERENCES flashcard_sets(id),
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  order_index INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createCardProgressTable = '''
CREATE TABLE IF NOT EXISTS card_progress (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id),
  card_id TEXT NOT NULL REFERENCES flashcards(id),
  status TEXT NOT NULL,
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(user_id, card_id)
)
''';

const createLearningSessionsTable = '''
CREATE TABLE IF NOT EXISTS learning_sessions (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id),
  set_id TEXT NOT NULL REFERENCES flashcard_sets(id),
  status TEXT NOT NULL,
  known_count INTEGER DEFAULT 0,
  unknown_count INTEGER DEFAULT 0,
  duration_seconds INTEGER,
  started_at TEXT NOT NULL,
  ended_at TEXT,
  last_card_index INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createSessionCardsTable = '''
CREATE TABLE IF NOT EXISTS session_cards (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  session_id TEXT NOT NULL REFERENCES learning_sessions(id),
  card_id TEXT NOT NULL REFERENCES flashcards(id),
  card_front TEXT NOT NULL,
  card_back TEXT NOT NULL,
  status TEXT NOT NULL,
  order_index INTEGER,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createFavoriteSetsTable = '''
CREATE TABLE IF NOT EXISTS favorite_sets (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id),
  set_id TEXT NOT NULL REFERENCES flashcard_sets(id),
  created_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(user_id, set_id)
)
''';

const createClassroomsTable = '''
CREATE TABLE IF NOT EXISTS classrooms (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  teacher_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  description TEXT,
  join_code TEXT NOT NULL UNIQUE,
  is_join_enabled INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createClassMembersTable = '''
CREATE TABLE IF NOT EXISTS class_members (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  role TEXT NOT NULL,
  joined_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(classroom_id, user_id)
)
''';

const createAssignedSetsTable = '''
CREATE TABLE IF NOT EXISTS assigned_sets (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  set_id TEXT NOT NULL REFERENCES flashcard_sets(id),
  assigned_by_id TEXT NOT NULL REFERENCES users(id),
  due_at TEXT,
  created_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createAssignmentProgressTable = '''
CREATE TABLE IF NOT EXISTS assignment_progress (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  assigned_set_id TEXT NOT NULL REFERENCES assigned_sets(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL,
  completed_at TEXT,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(assigned_set_id, user_id)
)
''';

const createClassActivitiesTable = '''
CREATE TABLE IF NOT EXISTS class_activities (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  action TEXT NOT NULL,
  target_id TEXT,
  timestamp TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createQuizzesTable = '''
CREATE TABLE IF NOT EXISTS quizzes (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  teacher_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  source_set_id TEXT REFERENCES flashcard_sets(id),
  status TEXT NOT NULL,
  time_limit_seconds INTEGER,
  question_count INTEGER,
  shuffle_questions INTEGER DEFAULT 0,
  shuffle_answers INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createQuizQuestionsTable = '''
CREATE TABLE IF NOT EXISTS quiz_questions (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  quiz_id TEXT NOT NULL REFERENCES quizzes(id),
  question_text TEXT NOT NULL,
  correct_answer_index INTEGER NOT NULL,
  order_index INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createQuizOptionsTable = '''
CREATE TABLE IF NOT EXISTS quiz_options (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  question_id TEXT NOT NULL REFERENCES quiz_questions(id),
  option_text TEXT NOT NULL,
  order_index INTEGER,
  is_correct INTEGER,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createQuizAttemptsTable = '''
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  quiz_id TEXT NOT NULL REFERENCES quizzes(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL,
  score INTEGER,
  total_questions INTEGER,
  time_taken_seconds INTEGER,
  started_at TEXT NOT NULL,
  submitted_at TEXT,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createQuizAnswersTable = '''
CREATE TABLE IF NOT EXISTS quiz_answers (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  attempt_id TEXT NOT NULL REFERENCES quiz_attempts(id),
  question_id TEXT NOT NULL REFERENCES quiz_questions(id),
  selected_option_index INTEGER,
  is_correct INTEGER,
  dirty_at TEXT,
  synced_at TEXT
)
''';

const createQuizAssignmentsTable = '''
CREATE TABLE IF NOT EXISTS quiz_assignments (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  quiz_id TEXT NOT NULL REFERENCES quizzes(id),
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  assigned_at TEXT NOT NULL,
  due_at TEXT,
  dirty_at TEXT,
  synced_at TEXT
)
''';

final List<String> kAllTableCreateStatements = [
  createUsersTable,
  createFlashcardSetsTable,
  createFlashcardsTable,
  createCardProgressTable,
  createLearningSessionsTable,
  createSessionCardsTable,
  createFavoriteSetsTable,
  createClassroomsTable,
  createClassMembersTable,
  createAssignedSetsTable,
  createAssignmentProgressTable,
  createClassActivitiesTable,
  createQuizzesTable,
  createQuizQuestionsTable,
  createQuizOptionsTable,
  createQuizAttemptsTable,
  createQuizAnswersTable,
  createQuizAssignmentsTable,
];
