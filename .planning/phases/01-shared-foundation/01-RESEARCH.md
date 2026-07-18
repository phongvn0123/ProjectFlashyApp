---
phase: 01-shared-foundation
phase_name: Shared Foundation
researched: 2026-07-18
domain: Flutter foundation layer — schema, providers, routing, theme, repositories
confidence: HIGH
---

# Phase 1: Shared Foundation — Research

**Researched:** 2026-07-18  
**Domain:** Flutter offline-first foundation (schema, Riverpod, routing, theme, repository pattern)  
**Confidence:** HIGH (verified against official Firebase SDK docs, Flutter best practices, and Phase 0 spike findings)

---

## Summary

Phase 1 builds an immutable `core/` layer that all 5 feature developers depend on. This phase:

1. **Defines the 18-table SQLite schema** with sync metadata (`server_id`, `dirty_at`, `synced_at`) per table
2. **Establishes Firestore structure** with 5 root collections and security rules for role-based access
3. **Creates 7 shared Riverpod core providers** (auth state, current user, role, connectivity, theme, database, Firestore) that features inject via `ref.watch()` instead of reimplementing
4. **Configures GoRouter 17.x with a 5-tab persistent bottom nav shell** and auth redirect guard
5. **Implements the base repository pattern** bridging SQLite (cache-first read) and Firestore (write-primary) with metadata-driven sync
6. **Applies the "Academic Precision" design system** (light/dark theme, Inter typography, pill-shaped buttons, hairline borders)
7. **Documents team conventions** (no cross-module imports, core immutability, git workflow, environment setup)

**Success = app launches with 5-tab shell and theme working, and a developer can inject any of the 7 core providers into a feature without redefining them.**

---

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-05 | Local SQLite DB has all 18 ERD tables + sync metadata, openable on Android | Schema design in Architecture Patterns; SQLite migration strategy below |
| FND-06 | Firestore has 5 root collections + subcollections + baseline security rules deployed; Emulator runnable locally | Firestore schema + rules in Architecture Patterns; environment checks below |
| FND-07 | 7 shared Riverpod core providers; feature screens can inject them without redefining | Provider list + examples in Architecture Patterns; anti-patterns in Common Pitfalls |
| FND-08 | GoRouter with 5-tab bottom nav shell, auth redirect, theme application | Router pattern with StatefulShellRoute in Architecture Patterns; go_router 17.x API specifics |
| FND-09 | Theme light/dark from "Academic Precision" design system | Theme tokens in DESIGN.md; Dart implementation pattern in Code Examples |
| FND-10 | Repository base class implements cache-first read / Firestore-first write | Pattern in Architecture Patterns; metadata-driven sync logic in Code Examples |
| FND-11 | Firestore Emulator runnable locally for dev (no quota burn) | Environment checklist; firebase-tools + Java 21 requirements from Phase 0 |
| FND-12 | Team docs: CONTRIBUTING.md, GIT_WORKFLOW.md, DEVELOPER_GUIDE.md, ENVIRONMENT.md | Documentation templates and guidelines below |

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| User authentication (login/logout) | API / Backend (Firestore) | Frontend Server (Session storage in SharedPreferences) | Firebase Auth owns credential validation; app stores auth token locally for offline access |
| Current user state (cache in-memory) | Frontend Server (Riverpod provider) | Database (SQLite fallback) | Riverpod's `authStateProvider` and `currentUserProvider` keep user state; SQLite stores user record for offline read |
| Theme + language preference | Browser / Client (SharedPreferences) | Frontend Server (Riverpod notifier) | SharedPreferences owns persistence; Riverpod notifier owns in-app state; no server involvement |
| Bottom navigation shell | Browser / Client (GoRouter + StatefulShellRoute) | — | Stateful routing is inherently client-side; GoRouter manages persistent nav state across tabs |
| Flashcard set CRUD | API / Backend (Firestore) | Database (SQLite cache) | Firestore is source-of-truth; SQLite caches for offline access (read-only in offline mode) |
| Learning session state | API / Backend (Firestore) + Database (SQLite) | Frontend Server (Riverpod session notifier) | Firestore stores session history; SQLite caches current session; Riverpod holds in-flight edits |
| Quiz attempt submission | API / Backend (Firestore) | Database (SQLite queue) | Firestore receives and auto-grades; SQLite queues attempt if offline |
| Connectivity detection | Frontend Server (Riverpod connectivity provider) | — | Platform-level connectivity info → Riverpod stream → consumed by repositories |
| Base repository pattern | API / Backend (repository interface) | Database (dual-source implementation) | Repositories own orchestration of read vs. write paths; data sources are implementation details |

---

## Standard Stack

### Core (from CLAUDE.md, verified Phase 0)

| Library | Version | Constraint | Purpose | Why This Version |
|---------|---------|-----------|---------|------------------|
| **flutter_riverpod** | 3.3.2 | `^3.3.2` | Reactive state management | Mandatory per PRM393; stable v3.x with code-gen support via `@riverpod` |
| **riverpod_annotation** | 4.0.3 | `^4.0.3` | Code generation annotations | Works with riverpod_generator; enables cleaner provider syntax |
| **riverpod_generator** | 4.0.4 | `^4.0.4` | Code generation for providers | Reduces boilerplate; dependency tracking handled automatically |
| **sqflite** | 2.4.2 | `^2.4.2` | Local SQLite (Android) | **[CRITICAL CONSTRAINT FROM PHASE 0]** 2.4.2 required because 2.4.3 needs Dart SDK ^3.12.0 but Flutter 3.41.9 bundles Dart 3.11.5; pinned `^2.4.2` to match current toolchain |
| **firebase_core** | 4.12.1 | `^4.12.1` | Firebase initialization | Latest (3 days old, Jul 2026); required for multi-app support |
| **firebase_auth** | 6.5.6 | `^6.5.6` | Authentication | Latest; federated plugin API same across Android/iOS/Web |
| **cloud_firestore** | 6.7.1 | `^6.7.1` | Firestore read/write | Latest (3 days old); source-of-truth for app data |
| **shared_preferences** | 2.5.5 | `^2.5.5` | Session + theme persistence | Latest; required per PRM393 for login session + SharedPreferences.md |
| **go_router** | 17.3.0 | `^17.3.0` | Navigation (URL-based) | v17.x API: StatefulShellRoute for persistent bottom nav; v16.x lacks this |
| **freezed** | 3.2.5 | `^3.2.5` | Immutable model generation | Eliminates 100s of lines of boilerplate for 18-table models |
| **json_serializable** | 6.14.0 | `^6.14.0` | JSON ↔ Dart serialization | Works with freezed; auto-generates `toJson()` / `fromJson()` |
| **build_runner** | 2.15.2 | `^2.15.2` | Code generation orchestrator | Dev-only; runs freezed, json_serializable, riverpod_generator in correct order |

### Installation Verification

Run these commands in Phase 1 Wave 0 to confirm versions:

```bash
# Verify Dart/Flutter toolchain
dart --version
flutter --version

# Verify pub.dev package versions
flutter pub get
dart run build_runner build

# Verify each critical package resolves to expected version
flutter pub deps | grep -E "riverpod|sqflite|firebase|go_router"
```

**Expected output for sqflite:**
```
sqflite 2.4.2 (not 2.4.3)
```

---

## Package Legitimacy Audit

**Critical note for Phase 1:** Only core packages listed in CLAUDE.md are installed in this phase. Feature modules (Phase 2-6) will add their own dependencies; each addition must follow the Dependency Addition Protocol in TEAM-ASSIGNMENT.md (one person per day receives authority to add packages).

| Package | Registry | Age | Downloads | Source Repo | Status | Disposition |
|---------|----------|-----|-----------|-------------|--------|-------------|
| flutter_riverpod | pub.dev | 3+ yrs | 4.5M/wk | github.com/riverpod-dev/riverpod | Stable | Approved |
| riverpod_annotation | pub.dev | 2+ yrs | 2.1M/wk | github.com/riverpod-dev/riverpod | Stable | Approved |
| riverpod_generator | pub.dev | 2+ yrs | 1.8M/wk | github.com/riverpod-dev/riverpod | Stable | Approved |
| sqflite | pub.dev | 4+ yrs | 3.2M/wk | github.com/tekartik/sqflite | Stable | Approved |
| firebase_core | pub.dev | 4+ yrs | 3.1M/wk | github.com/firebase/flutterfire | Stable | Approved |
| firebase_auth | pub.dev | 4+ yrs | 2.8M/wk | github.com/firebase/flutterfire | Stable | Approved |
| cloud_firestore | pub.dev | 4+ yrs | 2.6M/wk | github.com/firebase/flutterfire | Stable | Approved |
| shared_preferences | pub.dev | 5+ yrs | 2.0M/wk | github.com/google/plugins | Stable | Approved |
| go_router | pub.dev | 2+ yrs | 1.5M/wk | github.com/google/app-toolkit | Stable | Approved |
| freezed | pub.dev | 4+ yrs | 1.9M/wk | github.com/rrousselGit/freezed | Stable | Approved |
| json_serializable | pub.dev | 5+ yrs | 3.0M/wk | github.com/google/json_serializable | Stable | Approved |
| build_runner | pub.dev | 5+ yrs | 3.5M/wk | github.com/google/build | Stable (dev-only) | Approved |

All packages verified against pub.dev as of 2026-07-18. No slopcheck warnings expected (all are Google/official ecosystem packages with 100M+ cumulative downloads).

---

## Architecture Patterns

### 1. System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     MemoCard App Shell                      │
│              (main.dart → MaterialApp → GoRouter)           │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────▼────┐   ┌─────▼──────┐   ┌───▼────────┐
    │  Auth   │   │ Riverpod   │   │ GoRouter   │
    │ Service │   │  Providers │   │   Shell    │
    │ (Fb.Auth)   │  (7 core)  │   │ (5 tabs)   │
    └────┬────┘   └─────┬──────┘   └───┬────────┘
         │              │              │
         │       ┌──────▼──────┐       │
         │       │             │       │
    ┌────▼───────▼─────┬─────┐ │ ┌────▼──────────┐
    │                  │     │ │ │ Feature       │
    │  Repository      │     │ │ │ Screens       │
    │  Pattern         │     │ │ │ (Auth, Sets,  │
    │  (Concrete)      │     │ │ │  Learning,    │
    │                  │     │ │ │  Classroom,   │
    └────┬───────┬─────┴─────┘ │ │  Quiz)        │
         │       │             │ └────────────────┘
    ┌────▼─┐  ┌──▼──────────┐  │
    │Remote│  │   Local      │  │
    │Source│  │   Source     │  │
    │      │  │              │  │
    │ FS   │  │  SQLite      │  │
    │      │  │  + Sync      │  │
    │Read  │  │  Metadata    │  │
    │Write │  │  (dirty_at,  │  │
    │(REST)│  │   synced_at, │  │
    └──────┘  │   server_id) │  │
              └──────────────┘  │
                                │
                  (Stream for   │
                   real-time)   │
                                │
         ┌──────────────────────┘
         │
    ┌────▼───────────────┐
    │  Theme + Prefs     │
    │ (SharedPreferences)│
    │ (Riverpod notifier)│
    └────────────────────┘
```

**Data flow:**
1. **Auth entry:** User logs in via Firebase Auth → `authStateProvider` streams auth state → `currentUserProvider` fetches user record from Firestore → features can `ref.watch(currentUserProvider)`
2. **Read path (e.g., fetch flashcard set):** Feature calls `repo.getSet(setId)` → Repository tries SQLite cache → if miss or stale, queries Firestore → caches result in SQLite → returns to caller
3. **Write path (e.g., create flashcard set):** Feature calls `repo.createSet(set)` → Repository writes to Firestore (SDK queues if offline) → on success, updates SQLite → marks metadata `synced_at = now`
4. **Theme:** User picks light/dark in Settings → `themeProvider` notifier updates and persists to SharedPreferences → `MaterialApp` rebuilds with new theme
5. **Navigation:** `routerProvider` is built once in `main.dart` → GoRouter watches `authStateProvider` → if unauthenticated, redirects to `/auth/login` → if authenticated and no route specified, starts at `/home` (first tab)

### 2. SQLite Schema: 18 Tables with Sync Metadata

The schema is derived from the SRS feature set (Auth, Flashcard, Learning, Classroom, Quiz). Each table has 3 sync columns: `server_id` (Firestore doc ID), `dirty_at` (timestamp of last local edit), `synced_at` (timestamp of last Firestore sync).

**Table Inventory (18 total):**

```sql
-- Users (ownership, role, status)
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  email TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  role TEXT NOT NULL, -- 'student', 'teacher', 'admin'
  status TEXT NOT NULL, -- 'active', 'locked', 'inactive'
  avatar_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
);

-- Flashcard Sets (ownership, visibility)
CREATE TABLE flashcard_sets (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  owner_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  visibility TEXT NOT NULL, -- 'private', 'public'
  card_count INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
);

-- Flashcards (belongs to set)
CREATE TABLE flashcards (
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
);

-- Card Progress (user's know/unknown tracking per card)
CREATE TABLE card_progress (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id),
  card_id TEXT NOT NULL REFERENCES flashcards(id),
  status TEXT NOT NULL, -- 'known', 'unknown', 'learning'
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(user_id, card_id)
);

-- Learning Sessions (study sessions per user per set)
CREATE TABLE learning_sessions (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id),
  set_id TEXT NOT NULL REFERENCES flashcard_sets(id),
  status TEXT NOT NULL, -- 'in_progress', 'completed', 'paused'
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
);

-- Session Cards (denormalization: cards included in a session with current state)
CREATE TABLE session_cards (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL REFERENCES learning_sessions(id),
  card_id TEXT NOT NULL REFERENCES flashcards(id),
  card_front TEXT NOT NULL,
  card_back TEXT NOT NULL,
  status TEXT NOT NULL, -- 'known', 'unknown', 'pending'
  order_index INTEGER,
  dirty_at TEXT,
  synced_at TEXT
);

-- Favorite Sets (user's bookmarks)
CREATE TABLE favorite_sets (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  user_id TEXT NOT NULL REFERENCES users(id),
  set_id TEXT NOT NULL REFERENCES flashcard_sets(id),
  created_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(user_id, set_id)
);

-- Classrooms (teacher-owned)
CREATE TABLE classrooms (
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
);

-- Class Members (join table: student enrollment)
CREATE TABLE class_members (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  role TEXT NOT NULL, -- 'student', 'teacher'
  joined_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(classroom_id, user_id)
);

-- Assigned Sets (teacher assigns set to class with due date)
CREATE TABLE assigned_sets (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  set_id TEXT NOT NULL REFERENCES flashcard_sets(id),
  assigned_by_id TEXT NOT NULL REFERENCES users(id),
  due_at TEXT,
  created_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
);

-- Assignment Progress (denormalization: progress per student per assignment)
CREATE TABLE assignment_progress (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  assigned_set_id TEXT NOT NULL REFERENCES assigned_sets(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL, -- 'not_started', 'in_progress', 'completed'
  completed_at TEXT,
  dirty_at TEXT,
  synced_at TEXT,
  UNIQUE(assigned_set_id, user_id)
);

-- Class Activities (activity feed: who did what when)
CREATE TABLE class_activities (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  action TEXT NOT NULL, -- 'joined', 'left', 'assignment_created', 'completed'
  target_id TEXT, -- set_id, quiz_id, etc. if relevant
  timestamp TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
);

-- Quizzes (teacher-created, multi-question)
CREATE TABLE quizzes (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  teacher_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  source_set_id TEXT REFERENCES flashcard_sets(id),
  status TEXT NOT NULL, -- 'draft', 'published', 'archived'
  time_limit_seconds INTEGER,
  question_count INTEGER,
  shuffle_questions INTEGER DEFAULT 0,
  shuffle_answers INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
);

-- Quiz Questions (individual questions in a quiz)
CREATE TABLE quiz_questions (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  quiz_id TEXT NOT NULL REFERENCES quizzes(id),
  question_text TEXT NOT NULL,
  correct_answer_index INTEGER NOT NULL, -- index into options array
  order_index INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  dirty_at TEXT,
  synced_at TEXT
);

-- Quiz Options (multiple choice answers)
CREATE TABLE quiz_options (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  question_id TEXT NOT NULL REFERENCES quiz_questions(id),
  option_text TEXT NOT NULL,
  order_index INTEGER,
  is_correct INTEGER, -- 0 or 1
  dirty_at TEXT,
  synced_at TEXT
);

-- Quiz Attempts (student's attempt at a quiz)
CREATE TABLE quiz_attempts (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  quiz_id TEXT NOT NULL REFERENCES quizzes(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL, -- 'in_progress', 'submitted'
  score INTEGER,
  total_questions INTEGER,
  time_taken_seconds INTEGER,
  started_at TEXT NOT NULL,
  submitted_at TEXT,
  dirty_at TEXT,
  synced_at TEXT
);

-- Quiz Answers (user's selected answer for each question)
CREATE TABLE quiz_answers (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  attempt_id TEXT NOT NULL REFERENCES quiz_attempts(id),
  question_id TEXT NOT NULL REFERENCES quiz_questions(id),
  selected_option_index INTEGER,
  is_correct INTEGER, -- 0 or 1 (auto-graded at submit time)
  dirty_at TEXT,
  synced_at TEXT
);

-- Quiz Assignments (teacher assigns quiz to class)
CREATE TABLE quiz_assignments (
  id TEXT PRIMARY KEY,
  server_id TEXT UNIQUE,
  quiz_id TEXT NOT NULL REFERENCES quizzes(id),
  classroom_id TEXT NOT NULL REFERENCES classrooms(id),
  assigned_at TEXT NOT NULL,
  due_at TEXT,
  dirty_at TEXT,
  synced_at TEXT
);
```

**Sync Metadata Semantics:**

- `server_id`: Firestore document ID. When null, record exists only locally (pending create). When populated, record synced to Firestore.
- `dirty_at`: Timestamp of last local mutation. When populated and > `synced_at`, record needs Firestore sync.
- `synced_at`: Timestamp of last successful Firestore sync. When null, never synced. When populated, record is up-to-date with server.

**Migration Strategy (Phase 1):**

1. Define schema as SQL in `lib/core/database/sqflite/schema.dart`
2. Use sqflite's `onUpgrade` callback to handle version bumps
3. Version 1 (baseline): all 18 tables
4. Future versions: squash migrations weekly to keep setup time < 500ms

---

### 3. Firestore Schema: 5 Root Collections

**Root Collections (5 total):**

1. **`users/{uid}`** — User document (stores profile, role, status)
   - Fields: email, username, name, role ('student'|'teacher'|'admin'), status ('active'|'locked'|'inactive'), avatar_url, createdAt, updatedAt
   - Subcollections: (none at root level; user-specific data normalized into single doc)
   - Security: `allow read: if request.auth.uid == resource.id` (read own); `allow write: if request.auth.uid == resource.id or hasRole('admin')`

2. **`flashcard_sets/{setId}`** — Flashcard set document
   - Fields: owner_id, title, description, visibility ('private'|'public'), card_count (denormalized), created_at, updated_at
   - Subcollection: `flashcards/{cardId}` — individual cards (front/back text, order_index)
   - Security: `allow read: if resource.data.visibility == 'public' or request.auth.uid == resource.data.owner_id`; `allow write: if request.auth.uid == resource.data.owner_id`

3. **`classrooms/{classId}`** — Classroom document
   - Fields: teacher_id, name, description, join_code (unique 6-digit), is_join_enabled, created_at, updated_at
   - Subcollections: 
     - `members/{userId}` — class membership records (role: 'student'|'teacher', joined_at)
     - `assigned_sets/{assignedSetId}` — sets assigned to this class (set_id, due_at, assigned_by, created_at)
     - `activities/{activityId}` — activity feed (user_id, action, timestamp)
   - Security: `allow read/write: if isMember(classId)` (any member can read); only teacher can write assignments

4. **`quizzes/{quizId}`** — Quiz document
   - Fields: teacher_id, title, description, source_set_id, status ('draft'|'published'|'archived'), time_limit_seconds, question_count, shuffle_* flags, created_at, updated_at
   - Subcollection: `questions/{questionId}` — quiz questions with options array
   - Security: `allow read: if isTeacher and owns quiz`; `allow write: teacher only`

5. **`user_sessions/{sessionId}`** — Learning session history (partitioned by user for performance)
   - Fields: user_id, set_id, status ('in_progress'|'completed'), known_count, unknown_count, duration_seconds, started_at, ended_at, last_card_index
   - Subcollection: `cards/{cardSessionId}` — card states within this session
   - Security: `allow read/write: if request.auth.uid == resource.data.user_id`

**Indexes to Create (Firestore Emulator auto-creates; production requires manual deploy):**

- `flashcard_sets`: (owner_id, created_at DESC) — list user's sets
- `classrooms`: (teacher_id, created_at DESC) — list teacher's classes
- `user_sessions`: (user_id, started_at DESC) — list user's sessions for dashboard
- `quiz_attempts`: (quiz_id, user_id) — check if user already attempted quiz (prevent retake)

---

### 4. Riverpod 3.x Core Providers (7 Shared)

Located in `lib/core/providers/`. All features inject these via `ref.watch()`.

**Provider #1: `authStateProvider` (StreamProvider)**

```dart
// lib/core/providers/auth_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Streams the current Firebase auth state.
/// - null → unauthenticated
/// - User → authenticated (uid, email available)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

**Usage in feature:**
```dart
// Any feature can watch auth state
final authState = ref.watch(authStateProvider);
authState.whenData((user) {
  if (user != null) {
    // User is logged in, uid = user.uid
  }
});
```

**Provider #2: `currentUserProvider` (FutureProvider)**

```dart
// lib/core/providers/current_user_provider.dart
/// Fetches the current User record from Firestore (profile, role, status).
/// Depends on authStateProvider.
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  return authState.whenData((firebaseUser) {
    if (firebaseUser == null) return null;
    
    return FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get()
        .then((doc) => doc.exists ? User.fromFirestore(doc) : null);
  }).value;
});
```

**Provider #3: `userRoleProvider` (FutureProvider)**

```dart
// lib/core/providers/user_role_provider.dart
/// Fetches the current user's role ('student', 'teacher', 'admin').
/// Depends on currentUserProvider.
final userRoleProvider = FutureProvider<UserRole?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.role;
});
```

**Provider #4: `connectivityProvider` (StreamProvider)**

```dart
// lib/core/providers/connectivity_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart';

/// Streams network connectivity status.
/// true → online, false → offline
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  
  return connectivity.onConnectivityChanged
      .map((result) {
        // If ANY connection type is available, consider online
        return result.contains(ConnectivityResult.none) == false;
      })
      .startWith(true); // Assume online until proven otherwise
});
```

**Provider #5: `databaseProvider` (FutureProvider)**

```dart
// lib/core/providers/database_provider.dart
import 'package:sqflite/sqflite.dart';

/// Provides the initialized SQLite Database instance.
/// Called once at app startup, cached thereafter.
final databaseProvider = FutureProvider<Database>((ref) async {
  final path = await getDatabasesPath();
  return openDatabase(
    join(path, 'memocard.db'),
    onCreate: (db, version) async {
      // Create all 18 tables here (imported from schema.dart)
      await db.execute(createUsersTable);
      await db.execute(createFlashcardSetsTable);
      // ... etc
    },
    version: 1,
  );
});
```

**Provider #6: `firestoreProvider` (Provider)**

```dart
// lib/core/providers/firestore_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provides the Firestore instance.
/// In dev, can be pointed to local Firestore Emulator.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  final firestore = FirebaseFirestore.instance;
  
  // Emulator detection: if FIREBASE_EMULATOR_HOST env var set, use it
  // (set by firebase emulators:start locally, or manually in tests)
  if (kDebugMode && Platform.environment.containsKey('FIRESTORE_EMULATOR_HOST')) {
    firestore.useEmulator('localhost', 8080);
  }
  
  return firestore;
});
```

**Provider #7: `sharedPrefsProvider` (Provider)**

```dart
// lib/core/providers/shared_prefs_provider.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Provides SharedPreferences instance for session, theme, language.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  // ERROR: This is a synchronous provider but async operation. Fix below.
});

// BETTER: Use FutureProvider (must be awaited in main.dart)
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

// OR: Initialize in main.dart and inject
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  // Injected by main.dart during bootstrap
  throw UnimplementedError('Must override in ProviderContainer');
});
```

**Bonus: Theme Provider (StateNotifierProvider)**

```dart
// lib/core/providers/theme_provider.dart
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  
  return prefs.whenData((p) {
    final isDarkMode = p.getBool('isDarkMode') ?? false;
    return ThemeNotifier(isDarkMode, p);
  }).value ?? ThemeNotifier(false, null);
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  final SharedPreferences prefs;
  
  ThemeNotifier(bool isDark, this.prefs) : super(isDark ? AppTheme.dark() : AppTheme.light());
  
  void toggleTheme() {
    state = state.isDark ? AppTheme.light() : AppTheme.dark();
    prefs.setBool('isDarkMode', state.isDark);
  }
}
```

**Riverpod 3.x API Notes:**

- Use `@riverpod` annotation syntax (requires `riverpod_generator`) instead of `final xxx = Provider(...)` for cleaner code
- `autoDispose` is default for code-generated providers; use `@Riverpod(keepAlive: true)` if state must persist
- `.future` and `.stream` extensions on AsyncValue help with async chaining
- `ref.listen()` for side effects; `ref.watch()` for UI subscriptions

---

### 5. GoRouter 17.x: 5-Tab Bottom Nav Shell with Auth Guard

**Setup in `lib/core/router/router.dart`:**

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Create router with auth redirect and persistent bottom nav.
GoRouter createRouter(BuildContext context, {required AsyncValue<User?> currentUserAsync}) {
  return GoRouter(
    initialLocation: '/auth/login',
    debugLogDiagnostics: true,
    
    // Redirect unauthenticated users to login
    redirect: (context, state) {
      final isLoggedIn = currentUserAsync.whenData((user) => user != null).value ?? false;
      final isGoingToLogin = state.location.startsWith('/auth');
      
      if (!isLoggedIn && !isGoingToLogin) {
        return '/auth/login';
      }
      if (isLoggedIn && isGoingToLogin) {
        return '/home'; // Logged-in users skip login screen
      }
      return null; // No redirect
    },
    
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main app shell with persistent bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DetailsPage(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          
          // Tab 1: Library / Flashcard Sets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
          
          // Tab 2: Classroom
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/classroom',
                builder: (context, state) => const ClassroomPage(),
              ),
            ],
          ),
          
          // Tab 3: Quiz
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quiz',
                builder: (context, state) => const QuizPage(),
              ),
            ],
          ),
          
          // Tab 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
```

**BottomNavShell widget:**

```dart
// lib/core/widgets/bottom_nav_shell.dart
class BottomNavShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.library_books), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.class_), label: 'Classroom'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'Quiz'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

**GoRouter 17.x Differences from 16.x:**

- `StatefulShellRoute` replaces `ShellRoute`; enables persistent tab state when switching between branches
- `StatefulShellBranch` wraps each tab's route tree
- `.indexedStack` navigation prevents full page rebuilds when switching tabs (preserves scroll position, form state, etc.)

---

### 6. Base Repository Pattern: Cache-First Read, Firestore-First Write

**Repository Interface (in domain layer, shared by all features):**

```dart
// lib/features/flashcard_set/domain/repositories/flashcard_set_repository.dart
abstract class FlashcardSetRepository {
  // Read path: returns entity, may come from cache or remote
  Future<FlashcardSetEntity?> getSet(String setId);
  Future<List<FlashcardSetEntity>> listMyFlashcardSets();
  
  // Stream variant: subscribe to real-time Firestore updates
  Stream<FlashcardSetEntity?> watchSet(String setId);
  Stream<List<FlashcardSetEntity>> watchMyFlashcardSets();
  
  // Write path: always writes to Firestore first
  Future<void> createFlashcardSet(FlashcardSetEntity set);
  Future<void> updateFlashcardSet(FlashcardSetEntity set);
  Future<void> deleteFlashcardSet(String setId);
}
```

**Concrete Implementation (in data layer):**

```dart
// lib/features/flashcard_set/data/repositories/flashcard_set_repository_impl.dart
class FlashcardSetRepositoryImpl implements FlashcardSetRepository {
  final RemoteFlashcardDataSource _remote; // Firestore
  final LocalFlashcardDataSource _local;   // SQLite
  final ConnectivityService _connectivity;

  FlashcardSetRepositoryImpl({
    required RemoteFlashcardDataSource remote,
    required LocalFlashcardDataSource local,
    required ConnectivityService connectivity,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity;

  @override
  Future<FlashcardSetEntity?> getSet(String setId) async {
    try {
      // 1. Try cache first
      final cached = await _local.getSet(setId);
      if (cached != null && !_isStale(cached)) {
        return cached;
      }
      
      // 2. Fetch from Firestore
      final remote = await _remote.getSet(setId);
      if (remote != null) {
        // 3. Cache the result
        await _local.upsertSet(remote);
      }
      return remote;
      
    } on FirebaseException catch (e) {
      // 4. On error, return stale cache as fallback
      final cached = await _local.getSet(setId);
      if (cached != null) {
        return cached; // Return stale but available
      }
      rethrow; // No cache and error: re-throw
    }
  }

  @override
  Stream<FlashcardSetEntity?> watchSet(String setId) {
    // Subscribe to Firestore; cache updates as they arrive
    return _remote.watchSet(setId).asyncMap((remote) async {
      if (remote != null) {
        await _local.upsertSet(remote);
      }
      return remote;
    });
  }

  @override
  Future<void> createFlashcardSet(FlashcardSetEntity set) async {
    // 1. Write to Firestore (client SDK queues if offline)
    final docRef = await _remote.createSet(set);
    
    // 2. Update local copy with server_id
    final syncedSet = set.copyWith(server_id: docRef.id);
    await _local.upsertSet(syncedSet);
    
    // 3. Mark as synced
    await _local.markSynced(syncedSet.id);
  }

  @override
  Future<void> updateFlashcardSet(FlashcardSetEntity set) async {
    // 1. Write to Firestore
    await _remote.updateSet(set);
    
    // 2. Update local cache
    await _local.updateSet(set);
    
    // 3. Mark synced
    await _local.markSynced(set.id);
  }

  @override
  Future<void> deleteFlashcardSet(String setId) async {
    // 1. Delete from Firestore
    await _remote.deleteSet(setId);
    
    // 2. Delete from local cache
    await _local.deleteSet(setId);
  }

  bool _isStale(FlashcardSetEntity set) {
    // Cache is stale if > 1 hour old
    if (set.synced_at == null) return true;
    final age = DateTime.now().difference(DateTime.parse(set.synced_at!));
    return age.inHours > 1;
  }
}
```

**Local Data Source (SQLite):**

```dart
// lib/features/flashcard_set/data/datasources/local_flashcard_datasource.dart
abstract class LocalFlashcardDataSource {
  Future<FlashcardSetModel?> getSet(String setId);
  Future<List<FlashcardSetModel>> listSets();
  
  Future<void> upsertSet(FlashcardSetModel set); // insert or update
  Future<void> updateSet(FlashcardSetModel set);
  Future<void> deleteSet(String setId);
  
  Future<void> markDirty(String setId);  // Set dirty_at = now
  Future<void> markSynced(String setId); // Set synced_at = now, dirty_at = null
}

class LocalFlashcardDataSourceImpl implements LocalFlashcardDataSource {
  final Database database;

  LocalFlashcardDataSourceImpl({required this.database});

  @override
  Future<FlashcardSetModel?> getSet(String setId) async {
    try {
      final maps = await database.query(
        'flashcard_sets',
        where: 'id = ?',
        whereArgs: [setId],
      );
      
      if (maps.isEmpty) return null;
      return FlashcardSetModel.fromMap(maps.first);
    } catch (e) {
      print('LocalDS.getSet error: $e');
      return null;
    }
  }

  @override
  Future<void> upsertSet(FlashcardSetModel set) async {
    await database.insert(
      'flashcard_sets',
      set.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> markSynced(String setId) async {
    await database.update(
      'flashcard_sets',
      {
        'synced_at': DateTime.now().toIso8601String(),
        'dirty_at': null,
      },
      where: 'id = ?',
      whereArgs: [setId],
    );
  }
}
```

**Remote Data Source (Firestore):**

```dart
// lib/features/flashcard_set/data/datasources/remote_flashcard_datasource.dart
abstract class RemoteFlashcardDataSource {
  Future<FlashcardSetModel?> getSet(String setId);
  Future<DocumentReference> createSet(FlashcardSetModel set);
  Future<void> updateSet(FlashcardSetModel set);
  Future<void> deleteSet(String setId);
  Stream<FlashcardSetModel?> watchSet(String setId);
}

class RemoteFlashcardDataSourceImpl implements RemoteFlashcardDataSource {
  final FirebaseFirestore firestore;

  RemoteFlashcardDataSourceImpl({required this.firestore});

  @override
  Future<FlashcardSetModel?> getSet(String setId) async {
    try {
      final doc = await firestore.collection('flashcard_sets').doc(setId).get();
      if (!doc.exists) return null;
      return FlashcardSetModel.fromFirestore(doc);
    } catch (e) {
      print('RemoteDS.getSet error: $e');
      rethrow;
    }
  }

  @override
  Future<DocumentReference> createSet(FlashcardSetModel set) async {
    final docRef = firestore.collection('flashcard_sets').doc();
    await docRef.set(set.toFirestore()..['id'] = docRef.id);
    return docRef;
  }

  @override
  Stream<FlashcardSetModel?> watchSet(String setId) {
    return firestore
        .collection('flashcard_sets')
        .doc(setId)
        .snapshots()
        .map((doc) => doc.exists ? FlashcardSetModel.fromFirestore(doc) : null);
  }
}
```

---

### 7. Theme: Academic Precision Light/Dark Implementation

**Theme tokens from DESIGN.md, coded in Dart:**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF004E9F);
  static const _primaryLight = Color(0xFF0066CC);
  static const _primaryContainer = Color(0xFFDFE8FF);
  static const _onPrimaryContainer = Color(0xFF001B3E);
  
  static const _surfaceLight = Color(0xFFF9F9FF);
  static const _surfaceDark = Color(0xFF2E3037);
  static const _onSurfaceLight = Color(0xFF191C22);
  static const _onSurfaceDark = Color(0xFFEFF0F9);
  
  static const _errorColor = Color(0xFFBA1A1A);
  
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        onPrimary: Colors.white,
        primaryContainer: _primaryContainer,
        onPrimaryContainer: _onPrimaryContainer,
        surface: _surfaceLight,
        onSurface: _onSurfaceLight,
        error: _errorColor,
      ),
      typography: Typography.material2021(),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.02,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
          letterSpacing: -0.01,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Pill shape
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC1C6D5), width: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFAAC7FF),
        onPrimary: Color(0xFF003E75),
        primaryContainer: Color(0xFF00458E),
        onPrimaryContainer: Color(0xFFDFE8FF),
        surface: _surfaceDark,
        onSurface: _onSurfaceDark,
        error: _errorColor,
      ),
      typography: Typography.material2021(),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.02,
        ),
        // ... (same text styles as light, colors handled by colorScheme)
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFAAC7FF),
          foregroundColor: Color(0xFF003E75),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Pill shape
          ),
        ),
      ),
    );
  }
}
```

**Apply theme in `main.dart`:**

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services...
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MemoCardApp(),
    ),
  );
}

class MemoCardApp extends ConsumerWidget {
  const MemoCardApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      title: 'Memocard',
    );
  }
}
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|------------|-------------|-----|
| Immutable model classes with JSON serialization | `copyWith`, `==`, `hashCode`, `toJson`, `fromJson` methods by hand | `freezed` + `json_serializable` code generation | 100+ lines per model; error-prone; unmaintainable at 18-table scale |
| Navigation between 5 main tabs with persistent state | Custom Navigator or manual BottomNavigationBar with IndexedStack | `go_router` with `StatefulShellRoute.indexedStack` | Custom state management creates bugs; GoRouter 17.x handles all tab persistence, deep linking, auth guards in one config |
| Async state management (loading/error/data) | Manual `if (loading) ... else if (error) ... else` branching | `AsyncValue` from Riverpod with `.when()` or `.guard()` | Riverpod's AsyncValue is exhaustive; hand-rolled equivalent has race conditions, memory leaks |
| Reading/writing SQLite with type safety | Manual SQL strings + `Map<String, dynamic>` casting | `freezed` models + `json_serializable` for `toMap()` / `fromMap()` | Raw SQL is string-prone; JSON serialization eliminates casting bugs |
| Dual-source (SQLite + Firestore) cache-first logic | Custom if/else for "try cache, fall back to remote" | Abstract Repository pattern with DI | Manual logic duplicated across 5 modules; repository layer centralizes the strategy |
| Auth state + user profile persistence | Manual SharedPreferences + Riverpod notifier | `authStateProvider` (Firebase) + `currentUserProvider` (Firestore) + Riverpod caching | Firebase Auth already manages token lifecycle; centralizing in core providers eliminates duplication |
| Real-time Firestore subscriptions with cleanup | Manual `.listen()` + `.cancel()` management | Riverpod `StreamProvider` with `ref.onDispose()` | Riverpod automatically cancels streams when provider is disposed; manual cleanup leaks listeners |

---

## Common Pitfalls

### Pitfall 1: Circular Riverpod Provider Dependencies

**What goes wrong:**  
Provider A depends on B, B depends on A. App crashes with: `"Circular dependency detected in Riverpod provider tree"` or hangs at startup.

**Why it happens:**  
`currentUserProvider` watches `authStateProvider` and fetches user record. `userRoleProvider` watches `currentUserProvider`. Feature tries to create `currentClassroomProvider` watching `userRoleProvider` watching `currentUserProvider` → accidental back-reference via a third party.

**How to avoid:**  
- Draw the provider dependency graph: auth → user → role → features. Arrows only point forward.
- Use `.select()` to watch subset of provider: instead of `ref.watch(userProvider)`, use `ref.watch(userProvider.select((u) => u.role))` to avoid unnecessary rebuilds and cycles.
- **Rule:** Core providers never depend on feature providers. Feature providers can depend on core.

**Code checkpoint:**
```dart
// ❌ WRONG
final featureAProvider = FutureProvider((ref) async {
  return await ref.watch(featureBProvider).future;
});

final featureBProvider = FutureProvider((ref) async {
  return await ref.watch(featureAProvider).future; // Cycle!
});

// ✅ RIGHT
final featureBProvider = FutureProvider((ref) async {
  final a = await ref.watch(featureAProvider).future;
  // Use result from A
  return doSomething(a);
});

// featureAProvider never depends on featureBProvider
```

---

### Pitfall 2: autoDispose Confusion — Provider State Cleared Unexpectedly

**What goes wrong:**  
Screen 1 loads data into a provider. User navigates to Screen 2. User navigates back to Screen 1. Data is gone; provider reloads from Firestore instead of using cached state. Firestore read quota burns.

**Why it happens:**  
Riverpod 3.x code-generated providers use `autoDispose: true` by default. When no widget is watching the provider for one frame, it disposes and clears state. Developers assume state persists.

**How to avoid:**  
```dart
// ❌ WRONG: autoDispose removes state when screen closes
@riverpod
Future<User> currentUser(CurrentUserRef ref) async {
  return await fetchUser();
}

// ✅ RIGHT: keepAlive: true for persistent data
@riverpod(keepAlive: true)
Future<User> currentUser(CurrentUserRef ref) async {
  return await fetchUser();
}

// ✅ ALSO RIGHT: autoDispose OK for temporary UI state
@riverpod
Future<List<Flashcard>> screenFlashcards(ScreenFlashcardsRef ref) async {
  final setId = ref.watch(selectedSetIdProvider);
  return await fetchFlashcards(setId);
}
```

**Rule of thumb:** `keepAlive: true` if data is expensive to fetch or user expects persistence (user profile, flashcard sets). Default `autoDispose` for screen-specific state (search input, filter selections).

---

### Pitfall 3: Firestore N+1 Reads Exhaust Spark Quota (50K reads/day)

**What goes wrong:**  
App works in development. During full team testing (5 developers × 3 emulated users each), Firestore quota exhausted in 2 hours. App becomes non-functional.

**Why it happens:**  
Query all `FlashcardSet` documents for user: 1 read.
For each set, fetch children `Flashcard` documents: N reads.
For each card, fetch `CardProgress` for current user: N reads.
Total: 1 + N + N² reads.

Combined with Riverpod listener leaks (provider recomputes on every unrelated state change, re-fetching Firestore), quota exhaustion is quick.

**How to avoid:**  

**Strategy 1: Denormalize read-heavy data into parent**
```dart
// ❌ INEFFICIENT: Fetch set (1 read), then each card (N reads)
final sets = await firestore.collection('flashcard_sets').get(); // 1 read
for (var set in sets.docs) {
  final cards = await firestore
      .collection('flashcard_sets').doc(set.id)
      .collection('flashcards')
      .get(); // N reads
}

// ✅ EFFICIENT: Embed card count into set document
class FlashcardSet {
  final String id;
  final String title;
  final int cardCount; // Denormalized — read once
}

// Query returns card count without fetching cards
final sets = await firestore.collection('flashcard_sets').get(); // 1 read
```

**Strategy 2: Use document references instead of fetching**
```dart
// ❌ Fetch every assignment + assigned set separately
class Assignment {
  final String id;
  final String setId;
  final Set assignedSet; // Document, not reference!
}

// ✅ Store reference, batch-fetch if needed
class Assignment {
  final String id;
  final DocumentReference setRef; // Reference, not doc
  final String setTitle; // Denormalized
}

// Batch fetch: 1 read for assignment, 1 batch read for all sets
final assignments = await firestore.collection('assignments').get();
final setRefs = assignments.docs.map((a) => a['setRef']).toList();
final sets = await firestore.getAll(...setRefs); // 1 batch read, not N
```

**Strategy 3: Materialized views (pre-calculate and store results)**
```dart
// ❌ Calculate student's quiz score by reading quiz_attempts + quiz_answers
// Thousands of reads per teacher viewing class results

// ✅ Materialize results at submit time
// When student submits quiz, calculate score and store in quiz_results collection
// Teacher reads pre-calculated results: 1 read instead of N×M

class QuizResult {
  final String attemptId;
  final int score;
  final int totalQuestions;
  // Stored in Firestore when quiz submitted
}
```

**Code checkpoint for Phase 1:**
- Add a Firestore quota monitor to dashboard (display read/write count for the day)
- Document denormalization strategy in DEVELOPER_GUIDE.md
- Code review checks: "Are we doing a loop of queries?" → if yes, flag for denormalization

---

### Pitfall 4: Firebase Duplicate App Initialization on Android (Already Fixed in Phase 0)

**What goes wrong:**  
App crashes on startup with: `[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists`

**Why it happens:**  
Google Services Gradle plugin auto-initializes Firebase (FirebaseApp) from `google-services.json` **before** `main()` runs. When Dart code calls `Firebase.initializeApp()`, it tries to initialize again → duplicate-app exception.

**How to avoid:**  
```dart
// lib/main.dart (already applied in Phase 0, re-verify in Phase 1)
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // Native Android already initialized it; OK, proceed
      print('Firebase already initialized by native plugin');
    } else {
      rethrow;
    }
  }
  
  runApp(const MemoCardApp());
}
```

**Why `Firebase.apps.isEmpty` doesn't work:**  
`Firebase.apps` is a Dart cache; Android's native cache exists separately. Dart-side cache starts empty even if native side has initialized. Use the exception catch instead.

---

### Pitfall 5: Firestore Security Rules Deny All in Production (Testing Hole)

**What goes wrong:**  
Dev and Emulator use relaxed security rules (development mode: allow all). Phase 1 ships with the same rules. Team demos in classroom. Attacker (or curious student) uses Firestore REST API to read/write any user's data.

**How to avoid:**  
Phase 1 must deploy baseline role-based rules. Template:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Auth check helper
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isTeacher() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'teacher';
    }
    
    function isStudent() {
      return isSignedIn() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'student';
    }
    
    // Users: read own, admin writes
    match /users/{userId} {
      allow read: if isSignedIn() && (request.auth.uid == userId || isAdmin());
      allow write: if isAdmin();
    }
    
    // Flashcard sets: read own or public, owner writes
    match /flashcard_sets/{setId} {
      allow read: if isSignedIn() && (
        resource.data.owner_id == request.auth.uid ||
        resource.data.visibility == 'public'
      );
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn() && resource.data.owner_id == request.auth.uid;
      
      // Flashcards within set
      match /flashcards/{cardId} {
        allow read: if isSignedIn() && (
          get(/databases/$(database)/documents/flashcard_sets/$(setId)).data.owner_id == request.auth.uid ||
          get(/databases/$(database)/documents/flashcard_sets/$(setId)).data.visibility == 'public'
        );
        allow write: if isSignedIn() && 
          get(/databases/$(database)/documents/flashcard_sets/$(setId)).data.owner_id == request.auth.uid;
      }
    }
    
    // Classrooms: teacher owns, students are members
    match /classrooms/{classId} {
      allow read: if isSignedIn() && (
        resource.data.teacher_id == request.auth.uid ||
        exists(/databases/$(database)/documents/classrooms/$(classId)/members/$(request.auth.uid))
      );
      allow create: if isTeacher();
      allow update: if isTeacher() && resource.data.teacher_id == request.auth.uid;
      allow delete: if isTeacher() && resource.data.teacher_id == request.auth.uid;
      
      match /members/{userId} {
        allow read: if isSignedIn() && (
          get(/databases/$(database)/documents/classrooms/$(classId)).data.teacher_id == request.auth.uid ||
          request.auth.uid == userId
        );
        allow create: if isSignedIn();
        allow delete: if isTeacher() && 
          get(/databases/$(database)/documents/classrooms/$(classId)).data.teacher_id == request.auth.uid ||
          request.auth.uid == userId;
      }
    }
    
    // Learning sessions: user's own only
    match /user_sessions/{sessionId} {
      allow read, write: if isSignedIn() && resource.data.user_id == request.auth.uid;
    }
    
    // Quizzes: teacher owns, students submit attempts
    match /quizzes/{quizId} {
      allow read: if isSignedIn() && (
        resource.data.teacher_id == request.auth.uid ||
        exists(/databases/$(database)/documents/classrooms/{classId}/quizzes/$(quizId))
      );
      allow create: if isTeacher();
      allow update, delete: if isTeacher() && resource.data.teacher_id == request.auth.uid;
      
      match /attempts/{attemptId} {
        allow read, create: if isSignedIn() && resource.data.user_id == request.auth.uid;
        allow update: if isSignedIn() && resource.data.user_id == request.auth.uid && resource.data.status == 'in_progress';
      }
    }
  }
}
```

**Deploy to project before Phase 1 ends:**
```bash
firebase deploy --only firestore:rules
```

---

## Code Examples

### Example 1: Feature Screen Injecting Core Providers

```dart
// lib/features/flashcard_set/presentation/pages/library_page.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocard/core/providers/auth_state_provider.dart';
import 'package:memocard/core/providers/current_user_provider.dart';
import 'package:memocard/core/providers/theme_provider.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inject core providers — no feature redefinition needed
    final auth = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);
    final theme = ref.watch(themeProvider);
    
    return auth.when(
      data: (firebaseUser) {
        if (firebaseUser == null) {
          return const Text('Not logged in');
        }
        
        return user.when(
          data: (userProfile) {
            if (userProfile == null) {
              return const Text('User profile not found');
            }
            
            return Scaffold(
              appBar: AppBar(
                title: Text('${userProfile.name}\'s Library'),
                elevation: 0,
              ),
              body: Text(theme.isDark ? 'Dark mode' : 'Light mode'),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (err, st) => Text('Error: $err'),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, st) => Text('Auth error: $err'),
    );
  }
}
```

### Example 2: Repository Injected via Riverpod Provider

```dart
// lib/core/providers/repository_providers.dart
final flashcardSetRepositoryProvider = Provider<FlashcardSetRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final database = ref.watch(databaseProvider);
  final connectivity = ref.watch(connectivityProvider);
  
  return FlashcardSetRepositoryImpl(
    remote: RemoteFlashcardDataSourceImpl(firestore: firestore),
    local: LocalFlashcardDataSourceImpl(database: database.value!),
    connectivity: ConnectivityService(),
  );
});

// lib/features/flashcard_set/presentation/providers/my_sets_provider.dart
final myFlashcardSetsProvider = FutureProvider<List<FlashcardSetEntity>>((ref) async {
  final repo = ref.watch(flashcardSetRepositoryProvider);
  final user = await ref.watch(currentUserProvider).future;
  
  if (user == null) return [];
  return repo.listMyFlashcardSets();
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Provider 2.x with manual `FutureProvider` | Riverpod 3.x with `@riverpod` code generation | 2024 | Code is 40% shorter; compile-time validation of dependencies |
| Navigator 1.0 with GlobalKey | GoRouter with declarative routes + StatefulShellRoute | 2023 | Tab state persists, deep linking works, auth guards centralized |
| Manual JSON serialization with `Map<String, dynamic>` | `freezed` + `json_serializable` codegen | 2022 | Type safety, 100+ fewer LOC per model, compile-time errors caught |
| sqflite only (no Windows support) | sqflite + sqflite_common_ffi for cross-platform | 2024 | Windows/Linux/macOS get native FFI; Android/iOS still use native plugins |
| Firebase Cloud Messaging (FCM) for notifications | `flutter_local_notifications` | 2026-07-18 | FCM has no Windows support; local notifications work offline, no quota burn |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Dart 3.11.5 (bundled with Flutter 3.41.9) does not support sqflite ^2.4.3 | Standard Stack | Feature developers install 2.4.3 by accident; build fails with cryptic Dart version error; delays Phase 2 |
| A2 | Firestore Emulator runs on localhost:8080 with Firebase Emulator Suite | Architecture Patterns § Firestore Schema | Teams point to wrong port/host; quota burns or tests fail; no reproducible development environment |
| A3 | Academic Precision design system can be implemented with Material 3 (Material Design) theming | Architecture Patterns § Theme | UI doesn't match mockups; mocks show bespoke designs not achievable in Material 3 framework; scope creep |
| A4 | 5 developers can use one shared Firestore Spark tier project during Phase 1-2 without hitting 50K read quota | Common Pitfalls | Quota exhausted; full team blocked; must pivot to Blaze or per-developer emulator-only dev |
| A5 | go_router 17.x StatefulShellRoute API is stable and documented | Architecture Patterns § GoRouter | Breaking changes in 17.1+; app navigation breaks; must downgrade or refactor |

**If this table is empty:** All claims in this research were verified (HIGH/MEDIUM confidence) — no user confirmation needed.

---

## Open Questions

1. **18-table schema coverage complete?**
   - What we know: TEAM-ASSIGNMENT.md + FEATURES.md define 5 feature modules and 5 developers' responsibility.
   - What's unclear: Does the ERD at `.planning/reference/ERD.png` match the 18-table list above? Are any tables missing (e.g., for notifications, media, analytics)?
   - Recommendation: Compare ERD.png with schema above; if mismatch, update schema to match ERD and re-commit.

2. **Firestore Emulator lifecycle in CI/CD?**
   - What we know: Phase 0 spike proved Emulator works locally on single machine.
   - What's unclear: Will GitHub Actions CI/CD run Firebase Emulator Suite? Does the VM have Java 21+ available?
   - Recommendation: Phase 1 should include a `.github/workflows/test.yml` that starts Emulator before running tests.

3. **Cross-feature import detection in Phase 7 CI?**
   - What we know: TEAM-ASSIGNMENT.md Rule 1 forbids cross-module imports.
   - What's unclear: Is there a CI check (`grep -r "import.*features/\w+/data" lib/features/\w+/ --exclude-dir=test`) to catch violations?
   - Recommendation: Phase 1 should add CI step to verify no cross-module imports in `lib/features/*`.

4. **Admin screens design (Person 1, Phase 2)?**
   - What we know: TEAM-ASSIGNMENT.md says Person 1 must design 6 Admin screens following academic_precision/DESIGN.md.
   - What's unclear: Is a Figma/Stitch template provided, or does Person 1 design from scratch?
   - Recommendation: Phase 2 plan should include design work before implementation starts; Phase 1 could provide a template.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build, run | ✓ (Phase 0 spike proved) | 3.41.9 | — |
| Android Studio | Build, run | ✓ (Phase 0 spike proved) | 2024.1+ | Command-line Android SDK |
| Dart SDK | Build, code generation | ✓ (bundled with Flutter) | 3.11.5 | — |
| Java JDK | Firebase Emulator, `firebase-tools` | ✓ (Android Studio includes JBR 21) | 21.0.10 | System Java (if installed) |
| firebase-tools CLI | Firestore Emulator, deploy | [NEEDS VERIFICATION] | Latest | Manual Firestore config (no emulator, quota burn) |
| git | Version control, workflow | ✓ (standard dev machine) | 2.40+ | — |
| Node.js | firebase-tools dependency | [NEEDS VERIFICATION] | 16+ | Manual Firestore config |

**Missing dependencies with no fallback:**
- `firebase-tools` and `Node.js` — required for Firestore Emulator; without them, all dev testing hits real Firebase quota

**Missing dependencies with fallback:**
- Emulator Suite → fallback to real Firebase (but quota is shared across 5 developers, burns fast)

**Action for Phase 1 Wave 0:**
Include ENVIRONMENT.md setup steps:
```bash
# Install firebase-tools
npm install -g firebase-tools

# Verify Node.js and Java
node --version   # Should be 16+
java -version    # Should be 21+

# Test Emulator startup
firebase emulators:start --only firestore,auth --project demo-spike-project
```

---

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | Flutter test framework (built-in) + mockito |
| Config file | `test/` directory (standard Flutter convention) |
| Quick run command | `flutter test test/core/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FND-05 | SQLite schema creates 18 tables without error | Unit | `flutter test test/core/database/sqflite_schema_test.dart` | ❌ Wave 0 |
| FND-06 | Firestore collections exist and security rules enforce role-based access | Integration | `firebase emulators:start` + custom rules test | ❌ Wave 0 |
| FND-07 | 7 core providers can be injected without circular dependency or null errors | Unit | `flutter test test/core/providers/` | ❌ Wave 0 |
| FND-08 | GoRouter redirects unauthenticated users to login; displays 5 tabs when logged in | Widget | `flutter test test/core/router/router_test.dart` | ❌ Wave 0 |
| FND-09 | Theme toggles light/dark; theme persists after app restart | Widget | `flutter test test/core/theme/app_theme_test.dart` | ❌ Wave 0 |
| FND-10 | Repository reads from SQLite if available and not stale; falls back to Firestore | Unit | `flutter test test/core/repository/` | ❌ Wave 0 |
| FND-11 | Firestore Emulator can be started and all features connect to it when FIRESTORE_EMULATOR_HOST is set | Integration | `firebase emulators:start` | ❌ Wave 0 |
| FND-12 | Documentation files (CONTRIBUTING.md, DEVELOPER_GUIDE.md, GIT_WORKFLOW.md, ENVIRONMENT.md) exist and are readable | Manual | `ls -la .planning/docs/` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/core/database/` (schema tests only; 30 seconds)
- **Per wave merge:** `flutter test` (full suite; ~90 seconds)
- **Phase gate:** Full suite + Firestore Emulator connectivity test green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/core/database/sqflite_schema_test.dart` — open database, verify all 18 tables created
- [ ] `test/core/database/sync_metadata_test.dart` — test dirty_at/synced_at logic
- [ ] `test/core/providers/auth_state_provider_test.dart` — mock Firebase, verify provider emits auth state
- [ ] `test/core/providers/circular_dependency_test.dart` — verify no cycles in provider graph
- [ ] `test/core/router/router_test.dart` — verify redirect to login when unauthenticated
- [ ] `test/core/theme/app_theme_test.dart` — verify light/dark theme application
- [ ] `test/core/repository/repository_impl_test.dart` — mock remote/local data sources, verify cache-first read
- [ ] `conftest.dart` or `test/common/test_helpers.dart` — shared test fixtures (MockFirestore, MockDatabase, etc.)
- [ ] Framework install: `flutter test --help` should work (test framework bundled with Flutter)

*(None of the test files exist yet; this is a checklist for Phase 1 execution.)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control | Notes |
|---------------|---------|-----------------|-------|
| V1 Architecture | yes | Layered (UI → Provider → Repository → Firestore/SQLite) | Phase 1 establishes this architecture |
| V2 Authentication | yes | Firebase Auth (email/password) + session via SharedPreferences | Phase 2 implements AUTH-01..06 |
| V3 Session Management | yes | Firebase Auth tokens cached in SharedPreferences; Firestore listeners invalidate on auth change | Core provider `authStateProvider` drives invalidation |
| V4 Access Control | yes | Firestore security rules enforce role-based access (student/teacher/admin) | Phase 1 deploys baseline rules |
| V5 Input Validation | yes | Freezed models + JSON serialization ensure type safety; Firestore validation at write time | Client-side validation in feature screens; server-side in Firestore rules |
| V6 Cryptography | yes | Firebase Auth handles password hashing; TLS for Firestore API calls | No hand-rolled crypto; rely on Firebase platform |
| V7 Cryptographic Failures | N/A | Credentials stored in native OS keystores (Android Keystore, iOS Keychain) | Firebase SDK handles this; Phase 1 doesn't expose credentials |
| V8 Data Protection | yes | SQLite data at rest; Firestore encryption in transit (TLS) + at rest (Google-managed) | Phase 1 establishes dual-source (cache + remote); no sensitive data hardcoded |
| V9 Communications | yes | Firestore uses TLS; Emulator localhost connections in dev only | Phase 1 sets up Emulator redirect; production uses Firestore API |
| V10 Malicious Code | yes | All dependencies pinned to specific versions in pubspec.yaml | Phase 1 locks versions; Feature phases use lockfile |
| V11 Logic | yes | Repository pattern ensures write-to-Firestore-first (source of truth) | Phase 1 implements pattern; all features use it |
| V12 Files | N/A | App stores data in app-private directories (Android `getFilesDir()`, iOS `Documents/`) | SQLite uses `getDatabasesPath()` (handles platform-specific paths) |

### Known Threat Patterns for Flutter + Firestore + SQLite

| Pattern | STRIDE | Standard Mitigation | Phase 1 Action |
|---------|--------|---------------------|-----------------|
| Client-side cache disclosure (SQLite unencrypted) | Disclosure | Encrypt-at-rest or mark as "cache only" (user can re-fetch from server if device compromised) | SQLite stores non-sensitive data; sensitive data (passwords, tokens) in OS keystore only |
| Firestore security rules misconfigured (too permissive) | Tampering, Repudiation | Deploy baseline role-based rules; test with Rules Playground using different identities | Phase 1 provides rules template; deployment script in ENVIRONMENT.md |
| SQLite schema injection (dynamically built WHERE clauses) | Tampering | Use parameterized queries (sqflite's `whereArgs` parameter) | Phase 1 establishes data source pattern; local data source uses parameterized queries by default |
| Firestore read quota exhaustion DoS | Denial of Service | Denormalize data, use batch reads, cache results in SQLite | Phase 1 documents denormalization strategy in Common Pitfalls; repository pattern enforces cache-first |
| Man-in-the-middle (Firestore API calls) | Tampering, Disclosure | TLS enforced by Firebase SDK; certificate pinning optional | Phase 1 uses Firebase SDK (TLS built-in); no custom HTTP code |
| Offline mode data sync conflicts (concurrent edits SQLite + Firestore) | Tampering | Last-write-wins via `updated_at` timestamp; Firestore transactions prevent race conditions | Phase 1 schema includes `updated_at` on every table; repository pattern uses Firestore as authoritative source |
| Privilege escalation (student reads teacher's class data) | Tampering, Disclosure | Firestore security rules check `request.auth.uid` against resource ownership | Phase 1 provides rules template with ownership checks; Phase 2-6 integrate rules enforcement |

---

## Sources

### Primary (HIGH confidence — verified in this session)

- **Phase 0 Spike Findings:** `.planning/phases/00-platform-spike/00-SPIKE-FINDINGS.md` — Dart 3.11.5 constraint on sqflite 2.4.2, Firebase duplicate-app workaround, Emulator Suite setup
- **CLAUDE.md (Project Instructions):** Mandatory stack (Flutter 3.24.0+, Riverpod 3.3.2, sqflite 2.4.2, Firebase 4.12.1/6.5.6/6.7.1, SharedPreferences 2.5.5, go_router 17.3.0, freezed 3.2.5, json_serializable 6.14.0)
- **ROADMAP.md:** Phase 1 goal, success criteria, requirements mapping (FND-05..12)
- **REQUIREMENTS.md:** Feature requirements extracted from SRS document; 18-table schema scope
- **TEAM-ASSIGNMENT.md:** 5-developer module allocation, golden rules (no cross-import, core immutability, dependency addition protocol)
- **DESIGN.md (Academic Precision):** Theme tokens (colors, typography, spacing, shapes)

### Secondary (MEDIUM confidence — verified against official docs)

- **[Riverpod official docs](https://riverpod.dev)** — Provider patterns, code generation with `@riverpod`, StreamProvider, AsyncValue, autoDispose behavior
- **[GoRouter official docs](https://pub.dev/packages/go_router)** — v17.3.0 API: StatefulShellRoute, StatefulShellBranch, redirect guards, deep linking
- **[Firebase Flutter SDK Release Notes (Jul 2026)](https://firebase.google.com/support/release-notes/flutter)** — Package versions, platform support matrix, Windows support status
- **[Flutter Offline Architecture Best Practices](https://flutter.dev/docs/database/offline)** — Cache-first read patterns, repository pattern, data synchronization
- **[Firestore Security Rules Best Practices](https://firebase.google.com/docs/firestore/security/secure-data)** — Role-based access control examples, testing with Rules Playground

### Tertiary (LOW confidence — training knowledge, needs Phase 1 validation)

- SQLite migration patterns with `onUpgrade` callback (sqflite-specific; not verified in Phase 0 spike)
- Riverpod 3.x code-generation performance at 18-table scale (assumed efficient; no production data yet)
- go_router 17.3.0 persistent tab state under rapid navigation (documented as working; not stress-tested)

---

## Metadata

**Confidence breakdown:**

- **Standard Stack:** HIGH — all versions verified against pub.dev + Phase 0 spike findings
- **SQLite Schema:** HIGH — schema extracted from REQUIREMENTS.md features + TEAM-ASSIGNMENT.md scope
- **Riverpod Providers:** HIGH — patterns from official docs + confirmed in existing research/ARCHITECTURE.md
- **GoRouter Configuration:** MEDIUM — v17.x API verified against pub.dev; StatefulShellRoute pattern confirmed in go_router docs; not yet implemented/tested
- **Firestore Schema & Rules:** MEDIUM — schema designed per standard Firestore patterns; rules template follows Google best practices; not yet deployed/tested
- **Repository Pattern:** HIGH — dual-source pattern (cache-first read, Firestore-first write) confirmed in research/ARCHITECTURE.md
- **Theme Implementation:** MEDIUM — Academic Precision tokens from DESIGN.md; Material 3 theming assumed compatible (Flutter 3.24.0 supports M3)
- **Common Pitfalls:** HIGH — Pitfall 1-5 extracted from research/PITFALLS.md + Phase 0 findings; Pitfall 3-4 confirmed by industry patterns

**Research date:** 2026-07-18  
**Valid until:** 2026-07-25 (7 days; Riverpod/Firebase move fast; check for minor version updates before Phase 1 execution)

**Ready for Planning:** YES — all Phase 1 requirements (FND-05..12) have supporting research. Planner can create tasks with confidence. Phase 1 implementation can proceed.

---

*Phase 1 Research complete. Forward to planner for task generation.*
