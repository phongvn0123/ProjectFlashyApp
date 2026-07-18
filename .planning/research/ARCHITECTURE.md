# Architecture: Memocard Flutter Offline-First Flashcard App

**Project:** Memocard  
**Researched:** 2026-07-18  
**Confidence:** HIGH (Flutter best practices + Firebase documentation + multi-team patterns)

---

## Executive Summary

Memocard is a feature-first (vertical slice) monorepo for 5 parallel developers. Each developer owns a complete vertical slice: UI screens, business logic (Riverpod providers), and data access (repositories). A shared core layer provides foundation services (auth, database, routing, theme) that all features depend on.

**Key architectural decisions:**
- **Repository pattern:** Two data sources (Firestore remote + SQLite cache) composed at the repository layer
- **Read path:** Cache-first (check SQLite first), fall back to Firestore, cache result
- **Write path:** Write to Firestore directly (client-side SDK handles offline queueing), sync SQLite cache on success
- **State management:** Riverpod AsyncNotifierProvider for async state + StreamProvider for real-time Firestore subscriptions
- **Shared core:** Built in Phase 1 before 5 developers split; no feature module may modify core
- **Git safety:** Feature modules own their own folders + repositories entirely; shared core is read-only to features

---

## 1. Folder Structure: Feature-First Organization

### Project Tree (Concrete)

```
memocard/
├── lib/
│   ├── core/                           # [SHARED] Immutable foundation — Phase 1 only
│   │   ├── constants/
│   │   │   ├── app_config.dart
│   │   │   ├── enum_types.dart         # User.role, FlashcardSet.visibility, etc.
│   │   │   └── firestore_collections.dart  # Collection path constants
│   │   ├── database/
│   │   │   ├── sqflite/
│   │   │   │   ├── database_provider.dart  # Riverpod provider: Database instance
│   │   │   │   ├── database_service.dart   # Database initialization, migrations
│   │   │   │   └── schema.dart             # Table definitions (CREATE TABLE SQL)
│   │   │   └── models/
│   │   │       ├── local_user.dart
│   │   │       ├── local_flashcard_set.dart
│   │   │       ├── local_flashcard.dart
│   │   │       ├── local_learning_session.dart
│   │   │       ├── local_classroom.dart
│   │   │       ├── local_quiz.dart
│   │   │       └── sync_metadata.dart   # Tracks dirty_at, synced_at, server_id
│   │   ├── firebase/
│   │   │   ├── auth_provider.dart       # Riverpod: FirebaseAuth instance
│   │   │   ├── firestore_provider.dart  # Riverpod: FirebaseFirestore instance
│   │   │   ├── auth_service.dart        # Login, logout, password reset (no state)
│   │   │   └── firestore_config.dart    # Security rules constants, indexes
│   │   ├── providers/
│   │   │   ├── auth_state_provider.dart      # Current user + auth state (Riverpod)
│   │   │   ├── user_role_provider.dart       # Cached user role + permissions
│   │   │   ├── connectivity_provider.dart    # Network status stream
│   │   │   ├── theme_provider.dart           # Theme/language (from SharedPreferences)
│   │   │   ├── router_provider.dart          # GoRouter instance
│   │   │   └── shared_prefs_provider.dart    # SharedPreferences instance
│   │   ├── router/
│   │   │   ├── router.dart              # GoRouter configuration
│   │   │   └── routes.dart              # Route paths as constants
│   │   ├── theme/
│   │   │   ├── colors.dart
│   │   │   ├── typography.dart
│   │   │   └── app_theme.dart
│   │   ├── widgets/                     # Reusable UI components
│   │   │   ├── app_shell.dart
│   │   │   ├── bottom_nav_bar.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── empty_state.dart
│   │   │   └── error_widget.dart
│   │   └── utils/
│   │       ├── logger.dart
│   │       ├── extensions.dart          # DateTime, String, etc. extensions
│   │       └── validators.dart
│   │
│   ├── features/
│   │   │
│   │   ├── auth/                        # Auth + Profile + Admin (Person 1)
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── user_entity.dart
│   │   │   │   │   └── auth_state.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart  # Interface only
│   │   │   │   └── usecases/              # Use cases per SRS UC (UC1-UC15)
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── register_usecase.dart
│   │   │   │       ├── logout_usecase.dart
│   │   │   │       ├── fetch_profile_usecase.dart
│   │   │   │       ├── update_profile_usecase.dart
│   │   │   │       ├── change_password_usecase.dart
│   │   │   │       ├── admin_list_users_usecase.dart
│   │   │   │       ├── admin_update_user_role_usecase.dart
│   │   │   │       ├── admin_lock_account_usecase.dart
│   │   │   │       ├── admin_unlock_account_usecase.dart
│   │   │   │       ├── admin_reset_password_usecase.dart
│   │   │   │       └── admin_delete_user_usecase.dart
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── remote_auth_datasource.dart  # Firestore calls
│   │   │   │   │   └── local_auth_datasource.dart   # SQLite reads
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository_impl.dart    # Concrete impl
│   │   │   │   └── models/
│   │   │   │       ├── user_model.dart              # JSON serializable
│   │   │   │       └── auth_response_model.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   ├── auth_provider.dart           # Login/logout notifier
│   │   │   │   │   ├── user_profile_provider.dart   # Fetch/update profile
│   │   │   │   │   ├── admin_users_provider.dart    # List all users
│   │   │   │   │   ├── admin_single_user_provider.dart  # Fetch one user
│   │   │   │   │   └── admin_actions_provider.dart  # Role/lock/reset actions
│   │   │   │   ├── pages/
│   │   │   │   │   ├── login_page.dart
│   │   │   │   │   ├── register_page.dart
│   │   │   │   │   ├── profile_page.dart
│   │   │   │   │   ├── edit_profile_page.dart
│   │   │   │   │   ├── change_password_page.dart
│   │   │   │   │   ├── admin_users_list_page.dart
│   │   │   │   │   ├── admin_user_detail_page.dart
│   │   │   │   │   ├── admin_edit_user_page.dart
│   │   │   │   │   └── admin_permissions_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── login_form.dart
│   │   │   │       ├── register_form.dart
│   │   │   │       ├── user_list_item.dart
│   │   │   │       └── role_selector.dart
│   │   │   └── auth_module.dart          # Feature module export/dependency registration
│   │   │
│   │   ├── flashcard_set/               # Flashcard Set CRUD (Person 2)
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── flashcard_set_entity.dart
│   │   │   │   │   ├── flashcard_entity.dart
│   │   │   │   │   └── favorite_set_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   ├── flashcard_set_repository.dart
│   │   │   │   │   └── flashcard_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── create_set_usecase.dart
│   │   │   │       ├── list_sets_usecase.dart
│   │   │   │       ├── fetch_set_detail_usecase.dart
│   │   │   │       ├── update_set_usecase.dart
│   │   │   │       ├── delete_set_usecase.dart
│   │   │   │       ├── duplicate_set_usecase.dart
│   │   │   │       ├── add_favorite_usecase.dart
│   │   │   │       ├── remove_favorite_usecase.dart
│   │   │   │       ├── add_flashcard_usecase.dart
│   │   │   │       ├── update_flashcard_usecase.dart
│   │   │   │       └── delete_flashcard_usecase.dart
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── remote_flashcard_datasource.dart
│   │   │   │   │   └── local_flashcard_datasource.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   ├── flashcard_set_repository_impl.dart
│   │   │   │   │   └── flashcard_repository_impl.dart
│   │   │   │   └── models/
│   │   │   │       ├── flashcard_set_model.dart
│   │   │   │       └── flashcard_model.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   ├── my_sets_provider.dart          # List user's own sets
│   │   │   │   │   ├── set_detail_provider.dart       # Single set detail + cards
│   │   │   │   │   ├── create_set_provider.dart       # Create/edit state
│   │   │   │   │   ├── favorites_provider.dart        # Favorite sets list
│   │   │   │   │   └── public_sets_provider.dart      # Browse public sets
│   │   │   │   ├── pages/
│   │   │   │   │   ├── sets_list_page.dart
│   │   │   │   │   ├── set_detail_page.dart
│   │   │   │   │   ├── create_edit_set_page.dart
│   │   │   │   │   ├── favorites_page.dart
│   │   │   │   │   └── public_sets_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── set_card.dart
│   │   │   │       ├── set_list_item.dart
│   │   │   │       ├── flashcard_edit_form.dart
│   │   │   │       └── set_actions_menu.dart
│   │   │   └── flashcard_set_module.dart
│   │   │
│   │   ├── learning/                    # Learning Mode (Person 3)
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── learning_session_entity.dart
│   │   │   │   │   ├── card_progress_entity.dart
│   │   │   │   │   └── learning_state.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── learning_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── start_learning_usecase.dart
│   │   │   │       ├── resume_learning_usecase.dart
│   │   │   │       ├── answer_card_usecase.dart
│   │   │   │       ├── end_session_usecase.dart
│   │   │   │       ├── fetch_progress_usecase.dart
│   │   │   │       └── fetch_session_history_usecase.dart
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── remote_learning_datasource.dart
│   │   │   │   │   └── local_learning_datasource.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── learning_repository_impl.dart
│   │   │   │   └── models/
│   │   │   │       ├── learning_session_model.dart
│   │   │   │       └── session_card_model.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   ├── active_session_provider.dart    # Current learning state
│   │   │   │   │   ├── session_cards_provider.dart     # Cards in session
│   │   │   │   │   ├── card_progress_provider.dart     # Progress tracking
│   │   │   │   │   └── session_history_provider.dart   # Past sessions
│   │   │   │   ├── pages/
│   │   │   │   │   ├── learning_start_page.dart
│   │   │   │   │   ├── learning_card_page.dart
│   │   │   │   │   ├── learning_results_page.dart
│   │   │   │   │   └── progress_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── flashcard_flipper.dart
│   │   │   │       ├── card_actions.dart
│   │   │   │       ├── progress_indicator.dart
│   │   │   │       └── session_summary.dart
│   │   │   └── learning_module.dart
│   │   │
│   │   ├── classroom/                   # Classroom Management (Person 4)
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── classroom_entity.dart
│   │   │   │   │   ├── class_member_entity.dart
│   │   │   │   │   ├── assigned_set_entity.dart
│   │   │   │   │   ├── assignment_progress_entity.dart
│   │   │   │   │   └── class_activity_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── classroom_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── create_classroom_usecase.dart
│   │   │   │       ├── list_classes_usecase.dart
│   │   │   │       ├── fetch_class_detail_usecase.dart
│   │   │   │       ├── update_classroom_usecase.dart
│   │   │   │       ├── generate_code_usecase.dart
│   │   │   │       ├── join_classroom_usecase.dart
│   │   │   │       ├── assign_set_usecase.dart
│   │   │   │       ├── list_members_usecase.dart
│   │   │   │       ├── remove_member_usecase.dart
│   │   │   │       ├── fetch_activities_usecase.dart
│   │   │   │       └── fetch_assignment_progress_usecase.dart
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── remote_classroom_datasource.dart
│   │   │   │   │   └── local_classroom_datasource.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── classroom_repository_impl.dart
│   │   │   │   └── models/
│   │   │   │       ├── classroom_model.dart
│   │   │   │       ├── class_member_model.dart
│   │   │   │       └── assigned_set_model.dart
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   ├── my_classes_provider.dart        # Teacher's classes
│   │   │   │   │   ├── joined_classes_provider.dart    # Student's classes
│   │   │   │   │   ├── class_detail_provider.dart      # Single class detail
│   │   │   │   │   ├── class_members_provider.dart     # List members
│   │   │   │   │   ├── class_activities_provider.dart  # Activity stream
│   │   │   │   │   └── assignments_provider.dart       # Assigned sets
│   │   │   │   ├── pages/
│   │   │   │   │   ├── classes_list_page.dart
│   │   │   │   │   ├── class_detail_page.dart
│   │   │   │   │   ├── create_class_page.dart
│   │   │   │   │   ├── join_class_page.dart
│   │   │   │   │   ├── class_members_page.dart
│   │   │   │   │   ├── assignment_detail_page.dart
│   │   │   │   │   └── class_activity_page.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── class_card.dart
│   │   │   │       ├── member_list_item.dart
│   │   │   │       ├── assignment_card.dart
│   │   │   │       └── code_dialog.dart
│   │   │   └── classroom_module.dart
│   │   │
│   │   └── quiz/                        # Quiz/Test (Person 5)
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   ├── quiz_entity.dart
│   │       │   │   ├── quiz_question_entity.dart
│   │       │   │   ├── quiz_attempt_entity.dart
│   │       │   │   ├── quiz_answer_entity.dart
│   │       │   │   ├── quiz_assignment_entity.dart
│   │       │   │   └── quiz_attempt_state.dart
│   │       │   ├── repositories/
│   │       │   │   └── quiz_repository.dart
│   │       │   └── usecases/
│   │       │       ├── create_quiz_usecase.dart
│   │       │       ├── list_quizzes_usecase.dart
│   │       │       ├── publish_quiz_usecase.dart
│   │       │       ├── fetch_quiz_detail_usecase.dart
│   │       │       ├── assign_quiz_usecase.dart
│   │       │       ├── start_attempt_usecase.dart
│   │       │       ├── submit_answer_usecase.dart
│   │       │       ├── finish_attempt_usecase.dart
│   │       │       ├── fetch_attempt_result_usecase.dart
│   │       │       ├── fetch_class_results_usecase.dart
│   │       │       └── fetch_student_results_usecase.dart
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   ├── remote_quiz_datasource.dart
│   │       │   │   └── local_quiz_datasource.dart
│   │       │   ├── repositories/
│   │       │   │   └── quiz_repository_impl.dart
│   │       │   └── models/
│   │       │       ├── quiz_model.dart
│   │       │       ├── quiz_attempt_model.dart
│   │       │       └── quiz_answer_model.dart
│   │       ├── presentation/
│   │       │   ├── providers/
│   │       │   │   ├── my_quizzes_provider.dart       # Teacher's quizzes
│   │       │   │   ├── quiz_detail_provider.dart      # Single quiz detail
│   │       │   │   ├── active_attempt_provider.dart   # Current attempt
│   │       │   │   ├── quiz_results_provider.dart     # Results for teacher
│   │       │   │   ├── student_results_provider.dart  # Results for student
│   │       │   │   └── available_quizzes_provider.dart # Assigned quizzes for student
│   │       │   ├── pages/
│   │       │   │   ├── quizzes_list_page.dart
│   │       │   │   ├── quiz_detail_page.dart
│   │       │   │   ├── create_quiz_page.dart
│   │       │   │   ├── quiz_attempt_page.dart
│   │       │   │   ├── quiz_results_page.dart
│   │       │   │   ├── quiz_class_results_page.dart
│   │       │   │   └── available_quizzes_page.dart
│   │       │   └── widgets/
│   │       │       ├── quiz_card.dart
│   │       │       ├── question_builder.dart
│   │       │       ├── question_display.dart
│   │       │       ├── answer_option.dart
│   │       │       ├── results_summary.dart
│   │       │       └── class_results_table.dart
│   │       └── quiz_module.dart
│   │
│   └── main.dart
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### Folder Assignment (5 Developers)

| Developer | Module | Screens | Responsibility |
|-----------|--------|---------|-----------------|
| Person 1 | `auth/` | 10 (6 Auth + 4 Admin CRUD) | Login, register, logout, profile, admin user mgmt |
| Person 2 | `flashcard_set/` | 5 | Create/edit sets, view cards, favorites, browse public sets |
| Person 3 | `learning/` | 4 | Start session, study cards, track progress, view history |
| Person 4 | `classroom/` | 5 | Manage classes, assign sets, view members, track activities |
| Person 5 | `quiz/` | 3 | Create/publish quizzes, attempt, view results |

**Total: 27+ screens (each person owns 4+ as required)**

---

## 2. Repository Pattern: Dual Data Sources

### Data Source Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Feature (e.g., FlashcardSet)              │
│              Riverpod AsyncNotifierProvider             │
└─────────────────────────────────────────────────────────┘
                          │
                ┌─────────┴─────────┐
                │                   │
        ┌───────▼────────┐   ┌──────▼──────────┐
        │  Repository    │   │  StreamProvider │
        │  (Concrete)    │   │  (Real-time)    │
        └───────┬────────┘   └──────┬──────────┘
                │                   │
        ┌───────┴───────────────────┴──────┐
        │                                   │
  ┌─────▼──────────────┐    ┌─────────────▼──────────┐
  │  RemoteDataSource  │    │   LocalDataSource      │
  │  (Firestore)       │    │   (SQLite)             │
  │                    │    │                        │
  │  • Fetch docs      │    │  • Query cache         │
  │  • Stream changes  │    │  • Mark dirty          │
  │  • Batch write     │    │  • Sync metadata       │
  └─────────────────────┘    └─────────────────────────┘
```

### Read Path (Cache-First Strategy)

```dart
// Example: FlashcardSetRepository.getSet(setId)

Future<FlashcardSetEntity> getSet(String setId) async {
  try {
    // 1. Try local cache first
    final cached = await _localDataSource.getSet(setId);
    if (cached != null && !cached.isStale()) {
      return cached;
    }
    
    // 2. Fetch from remote (Firestore)
    final remote = await _remoteDataSource.getSet(setId);
    
    // 3. Update local cache
    await _localDataSource.upsertSet(remote);
    
    // 4. Return remote data
    return remote;
  } on FirebaseException catch (e) {
    // 4. On network error, try stale cache as fallback
    final cached = await _localDataSource.getSet(setId);
    if (cached != null) {
      return cached;
    }
    rethrow;
  }
}

// Stream variant for real-time updates
Stream<FlashcardSetEntity> watchSet(String setId) {
  // Subscribe to Firestore; cache updates as they arrive
  return _remoteDataSource.watchSet(setId).asyncMap((remote) async {
    await _localDataSource.upsertSet(remote);
    return remote;
  });
}
```

### Write Path (Firestore-Primary, Sync SQLite)

```dart
// Example: FlashcardSetRepository.updateSet()

Future<void> updateSet(FlashcardSetEntity set) async {
  // 1. Write to Firestore first (client SDK queues if offline)
  await _remoteDataSource.updateSet(set);
  
  // 2. On success, update local cache
  await _localDataSource.updateSet(set);
  
  // 3. Mark sync metadata as synced
  await _localDataSource.markSynced(set.id);
}

// Offline awareness
Future<void> createSet(FlashcardSetEntity set) async {
  final isOnline = await _connectivity.isConnected();
  
  if (isOnline) {
    // Direct write to Firestore
    await _remoteDataSource.createSet(set);
    await _localDataSource.upsertSet(set);
  } else {
    // Write locally + mark dirty; Firestore SDK will queue
    await _localDataSource.upsertSet(set);
    await _localDataSource.markDirty(set.id);
  }
}
```

### Repository Layer: Concrete Implementation

```dart
// lib/features/flashcard_set/data/repositories/flashcard_set_repository_impl.dart

class FlashcardSetRepositoryImpl implements FlashcardSetRepository {
  final RemoteFlashcardDataSource _remote;
  final LocalFlashcardDataSource _local;
  final ConnectivityService _connectivity;

  FlashcardSetRepositoryImpl({
    required RemoteFlashcardDataSource remote,
    required LocalFlashcardDataSource local,
    required ConnectivityService connectivity,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity;

  @override
  Future<List<FlashcardSetEntity>> listMyFlashcardSets() async {
    try {
      final remote = await _remote.listSets();
      await _local.upsertSets(remote);
      return remote;
    } on FirebaseException {
      return _local.listSets();
    }
  }

  @override
  Stream<List<FlashcardSetEntity>> watchMyFlashcardSets() {
    return _remote.watchSets().asyncMap((sets) async {
      await _local.upsertSets(sets);
      return sets;
    });
  }

  @override
  Future<void> createFlashcardSet(FlashcardSetEntity set) async {
    await _remote.createSet(set);
    await _local.upsertSet(set);
  }

  @override
  Future<void> updateFlashcardSet(FlashcardSetEntity set) async {
    await _remote.updateSet(set);
    await _local.updateSet(set);
  }

  @override
  Future<void> deleteFlashcardSet(String setId) async {
    await _remote.deleteSet(setId);
    await _local.deleteSet(setId);
  }
}
```

### Data Source Interfaces

```dart
// lib/features/flashcard_set/domain/repositories/flashcard_set_repository.dart
abstract class FlashcardSetRepository {
  Future<List<FlashcardSetEntity>> listMyFlashcardSets();
  Stream<List<FlashcardSetEntity>> watchMyFlashcardSets();
  Future<FlashcardSetEntity?> getSet(String setId);
  Future<void> createFlashcardSet(FlashcardSetEntity set);
  Future<void> updateFlashcardSet(FlashcardSetEntity set);
  Future<void> deleteFlashcardSet(String setId);
}

// lib/features/flashcard_set/data/datasources/remote_flashcard_datasource.dart
abstract class RemoteFlashcardDataSource {
  Future<List<FlashcardSetModel>> listSets();
  Stream<List<FlashcardSetModel>> watchSets();
  Future<FlashcardSetModel?> getSet(String setId);
  Future<void> createSet(FlashcardSetModel set);
  Future<void> updateSet(FlashcardSetModel set);
  Future<void> deleteSet(String setId);
}

// lib/features/flashcard_set/data/datasources/local_flashcard_datasource.dart
abstract class LocalFlashcardDataSource {
  Future<List<FlashcardSetModel>> listSets();
  Future<FlashcardSetModel?> getSet(String setId);
  Future<void> upsertSet(FlashcardSetModel set);
  Future<void> upsertSets(List<FlashcardSetModel> sets);
  Future<void> updateSet(FlashcardSetModel set);
  Future<void> deleteSet(String setId);
  Future<void> markDirty(String setId);
  Future<void> markSynced(String setId);
}
```

---

## 3. Riverpod Provider Organization

### Shared Core Providers (Phase 1)

All features depend on these. Located in `lib/core/providers/`.

```dart
// lib/core/providers/auth_state_provider.dart
final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges().map((user) {
    if (user == null) return AuthState.unauthenticated();
    return AuthState.authenticated(uid: user.uid);
  });
});

// lib/core/providers/current_user_provider.dart
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => 
    state.maybeMap(
      authenticated: (auth) => ref.watch(
        fetchUserProvider(auth.uid)
      ).value,
      orElse: () => null,
    ),
  ).value;
});

// lib/core/providers/database_provider.dart
final databaseProvider = FutureProvider<Database>((ref) async {
  return DatabaseService.instance.database;
});

// lib/core/providers/connectivity_provider.dart
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().onConnectivityChanged;
});

// lib/core/providers/router_provider.dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return createRouter(authState);
});

// lib/core/providers/theme_provider.dart
final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier(ref.watch(sharedPrefsProvider));
});
```

### Feature-Level Providers

Each feature module organizes providers in `presentation/providers/`. Example:

```dart
// lib/features/flashcard_set/presentation/providers/my_sets_provider.dart
final myFlashcardSetsProvider = FutureProvider<List<FlashcardSetEntity>>((ref) async {
  final repo = ref.watch(flashcardSetRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  
  return authState.whenData((state) =>
    state.maybeMap(
      authenticated: (_) => repo.listMyFlashcardSets(),
      orElse: () => [],
    ),
  ).value ?? [];
});

// Streaming variant: watch for real-time changes
final myFlashcardSetsStreamProvider = StreamProvider<List<FlashcardSetEntity>>((ref) {
  final repo = ref.watch(flashcardSetRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  
  return authState.whenData((state) =>
    state.maybeMap(
      authenticated: (_) => repo.watchMyFlashcardSets(),
      orElse: () => Stream.value([]),
    ),
  ).value ?? Stream.value([]);
});

// State mutation: AsyncNotifierProvider for create/update/delete
final createFlashcardSetProvider = 
    AsyncNotifierProvider<CreateSetNotifier, void>((ref) {
  return CreateSetNotifier(
    repo: ref.watch(flashcardSetRepositoryProvider),
  );
});

class CreateSetNotifier extends AsyncNotifier<void> {
  final FlashcardSetRepository repo;
  CreateSetNotifier({required this.repo});

  @override
  Future<void> build() async {}

  Future<void> createSet(FlashcardSetEntity set) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repo.createFlashcardSet(set),
    );
  }
}
```

### Provider Dependency Graph

```
authStateProvider [CORE]
    ├─> currentUserProvider [CORE]
    │   ├─> userRoleProvider [CORE]
    │   ├─> myFlashcardSetsProvider [flashcard_set]
    │   ├─> myClassesProvider [classroom]
    │   └─> myQuizzesProvider [quiz]
    │
databaseProvider [CORE]
    └─> All local data sources (via repository)

connectivityProvider [CORE]
    └─> Watched by repositories for offline detection

routerProvider [CORE] — used by main.dart shell
```

---

## 4. Core/Foundation Layer (Phase 1 Only)

What must be built BEFORE the 5 developers split off. This is immutable foundation.

### Concrete Checklist

#### A. App Shell & Routing
- [ ] `lib/main.dart` — bootstraps Riverpod, Firebase, GoRouter
- [ ] `lib/core/router/router.dart` — GoRouter configuration with auth guards
- [ ] `lib/core/router/routes.dart` — all route path constants
- [ ] `lib/core/widgets/app_shell.dart` — scaffold with bottom nav, status bar
- [ ] Navigation from all 5 feature modules configured

#### B. Firebase & Authentication
- [ ] `lib/core/firebase/firestore_provider.dart` — Riverpod provider for Firestore instance
- [ ] `lib/core/firebase/auth_provider.dart` — Riverpod provider for FirebaseAuth
- [ ] `lib/core/firebase/auth_service.dart` — login(), register(), logout(), passwordReset()
- [ ] `lib/core/firebase/firestore_config.dart` — collection path constants + rules reference
- [ ] `lib/core/providers/auth_state_provider.dart` — currentUser + authState stream
- [ ] Firebase project initialized, rules configured for all collections (see Section 5)

#### C. SQLite Initialization
- [ ] `lib/core/database/sqflite/database_service.dart` — singleton Database instance, migrations
- [ ] `lib/core/database/sqflite/schema.dart` — CREATE TABLE for all 18 tables (see Section 5)
- [ ] `lib/core/database/sqflite/database_provider.dart` — Riverpod provider
- [ ] Migration strategy documented (versioning, rollback approach)
- [ ] Android + Windows platform-specific setup verified

#### D. Shared Providers (Core)
- [ ] `authStateProvider` — currently logged-in user UID + auth state
- [ ] `currentUserProvider` — User document from Firestore (cached in SQLite)
- [ ] `userRoleProvider` — cached user role (admin/teacher/student) for permission checks
- [ ] `connectivityProvider` — network status stream
- [ ] `databaseProvider` — SQLite Database instance
- [ ] `sharedPrefsProvider` — SharedPreferences instance
- [ ] `themeProvider` — theme/language state (from SharedPrefs)
- [ ] `routerProvider` — GoRouter instance

#### E. Base Classes & Extensions
- [ ] `lib/core/utils/base_usecase.dart` — abstract UseCase<Params, Type>
- [ ] `lib/core/utils/failure.dart` — Failure sealed class (for error handling)
- [ ] `lib/core/utils/extensions.dart` — String, DateTime, List extensions
- [ ] `lib/core/utils/validators.dart` — email, password, etc. validators

#### F. Reusable Widgets
- [ ] `lib/core/widgets/loading_indicator.dart` — loading spinner
- [ ] `lib/core/widgets/empty_state.dart` — empty list widget
- [ ] `lib/core/widgets/error_widget.dart` — error message display
- [ ] `lib/core/widgets/bottom_nav_bar.dart` — 5-tab navigation (Home / Library / Classroom / Quiz / Profile)
- [ ] Material 3 theming (colors, typography) configured

#### G. Dependency Injection Setup
- [ ] Riverpod provider definitions for all core services (database, auth, firestore)
- [ ] Repository providers defined (as interfaces, each feature implements concrete)
- [ ] No hard-coded singletons; all dependencies via Riverpod

#### H. Connectivity & Offline Support
- [ ] `lib/core/providers/connectivity_provider.dart` — network status stream
- [ ] Fallback strategy documented (cache-first read, Firestore-primary write)
- [ ] Firestore offline persistence enabled in Firebase config

#### I. Constants & Enums
- [ ] `lib/core/constants/app_config.dart` — Firebase project ID, app name, version
- [ ] `lib/core/constants/enum_types.dart` — User.role, FlashcardSet.visibility, Quiz.status, etc.
- [ ] `lib/core/constants/firestore_collections.dart` — collection path strings

#### J. Error Handling & Logging
- [ ] `lib/core/utils/logger.dart` — centralized logging
- [ ] Exception mapping strategy (Firebase exceptions → app domain failures)
- [ ] Error widget for UI display of failures

#### K. Documentation
- [ ] `ARCHITECTURE.md` (this file) in `.planning/`
- [ ] `FIREBASE_SCHEMA.md` — Firestore collections, fields, indexes
- [ ] `DEVELOPER_GUIDE.md` — how to add a new feature, where repositories live, provider naming
- [ ] `GIT_WORKFLOW.md` — branch naming, commit style, conflict resolution

### Phase 1 Size Estimate
- **Time:** 3-4 days (1 developer setting up)
- **Files:** ~40 files (core/ folder only)
- **Blocker if late:** All 5 developers blocked; critical path

---

## 5. Firestore Schema Design

### Relational ERD → Document Store Mapping

The original 18-table relational schema must be mapped to Firestore collections and subcollections. This section shows the mapping with denormalization decisions.

### Collections Structure

```
firestore/
├── users/                               [Root collection]
│   ├── {userId}/
│   │   ├── basicFields: name, email, role, status, createdAt, lastLoginAt
│   │   ├── subcollection: flashcard_sets/
│   │   ├── subcollection: learning_sessions/
│   │   ├── subcollection: classrooms/         [Teacher-owned only]
│   │   └── subcollection: quiz_attempts/
│   │
├── flashcard_sets/                      [Root collection]
│   ├── {setId}/
│   │   ├── basicFields: title, description, visibility, owner_id, created_at, updated_at, card_count
│   │   ├── subcollection: flashcards/
│   │   └── subcollection: progress/          [DENORM: user progress]
│   │
├── classrooms/                          [Root collection]
│   ├── {classroomId}/
│   │   ├── basicFields: name, code, teacher_id, created_at
│   │   ├── subcollection: members/
│   │   ├── subcollection: assigned_sets/
│   │   ├── subcollection: activities/
│   │   └── subcollection: assignment_progress/
│   │
├── quizzes/                             [Root collection]
│   ├── {quizId}/
│   │   ├── basicFields: title, description, status, source_set_id, teacher_id, created_at
│   │   ├── subcollection: questions/
│   │   └── subcollection: attempts/
│   │
└── sync_metadata/                       [Root collection, SQLite-only]
    └── {entityId}/ -> (dirty_at, synced_at, server_version)
```

### Detailed Collection Schemas

#### 1. users/

```
users/ (Root)
  ├── {userId}
  │   ├── id: string (= uid from FirebaseAuth)
  │   ├── email: string
  │   ├── name: string
  │   ├── role: string (enum: admin | teacher | student)
  │   ├── status: string (enum: active | locked | inactive)
  │   ├── avatar_url: string (nullable)
  │   ├── created_at: timestamp
  │   ├── updated_at: timestamp
  │   ├── last_login_at: timestamp (nullable)
  │   │
  │   ├── subcollection: flashcard_sets/
  │   │   └── {setId} -> REFERENCE only
  │   │       └── { setId, title, created_at }  [DENORM for quick list]
  │   │
  │   ├── subcollection: learning_sessions/
  │   │   └── {sessionId}
  │   │       ├── set_id: string
  │   │       ├── set_title: string  [DENORM]
  │   │       ├── status: enum (in_progress | completed)
  │   │       ├── started_at: timestamp
  │   │       ├── ended_at: timestamp (nullable)
  │   │       ├── cards_learned: integer
  │   │       ├── cards_unknown: integer
  │   │       ├── subcollection: session_cards/
  │   │       │   └── {cardId}
  │   │       │       ├── card_id: string
  │   │       │       ├── front: string  [DENORM from flashcard_sets/*/flashcards/*/]
  │   │       │       ├── back: string   [DENORM]
  │   │       │       ├── status: enum (known | unknown)
  │   │       │       ├── answered_at: timestamp
  │   │       │       └── card_order: integer
  │   │       └── subcollection: card_progress/
  │   │           └── {cardId}
  │   │               ├── card_id: string
  │   │               ├── status: enum (known | unknown)
  │   │               ├── review_count: integer
  │   │               └── last_reviewed_at: timestamp
  │   │
  │   ├── subcollection: favorite_sets/
  │   │   └── {setId}
  │   │       ├── set_id: string
  │   │       ├── title: string  [DENORM]
  │   │       ├── added_at: timestamp
  │   │
  │   ├── subcollection: classrooms/          [Teacher only]
  │   │   └── {classroomId} -> REFERENCE
  │   │       └── { classroomId, name, created_at }
  │   │
  │   └── subcollection: quiz_attempts/
  │       └── {attemptId} -> REFERENCE
  │           └── { attemptId, quiz_id, status, submitted_at }
  │
  └── //{More users} ...
```

**Note on Denormalization:**
- User's flashcard_sets, learning_sessions, favorite_sets subcollections store references + cached titles for quick UI rendering
- Detailed data lives in root collections (flashcard_sets/, classrooms/, quizzes/)
- When a user views "My Sets", we query `users/{uid}/flashcard_sets` (fast, small) + fetch full set from `flashcard_sets/{setId}` if needed

#### 2. flashcard_sets/

```
flashcard_sets/ (Root)
  ├── {setId}
  │   ├── id: string
  │   ├── title: string
  │   ├── description: string
  │   ├── owner_id: string (reference to users/{uid})
  │   ├── visibility: enum (private | public)
  │   ├── card_count: integer
  │   ├── created_at: timestamp
  │   ├── updated_at: timestamp
  │   │
  │   ├── subcollection: flashcards/
  │   │   └── {cardId}
  │   │       ├── id: string
  │   │       ├── front: string
  │   │       ├── back: string
  │   │       ├── image_path: string (nullable)
  │   │       ├── audio_url: string (nullable)
  │   │       ├── order: integer
  │   │       ├── created_at: timestamp
  │   │       └── updated_at: timestamp
  │   │
  │   └── subcollection: progress/
  │       └── {userId}_{cardId}
  │           ├── user_id: string
  │           ├── card_id: string
  │           ├── status: enum (known | unknown)
  │           ├── review_count: integer
  │           ├── last_reviewed_at: timestamp
  │
  └── //{More sets} ...
```

**Hard Query Warning:** Firestore cannot efficiently query "all public sets by creation date". Mitigation: add `users/{uid}/public_sets` subcollection (denormalized list) or use a Search service.

#### 3. classrooms/

```
classrooms/ (Root)
  ├── {classroomId}
  │   ├── id: string
  │   ├── name: string
  │   ├── code: string (6-char invite code, unique index)
  │   ├── teacher_id: string (reference to users/)
  │   ├── teacher_name: string  [DENORM]
  │   ├── member_count: integer [DENORM, updated on member add/remove]
  │   ├── created_at: timestamp
  │   ├── updated_at: timestamp
  │   │
  │   ├── subcollection: members/
  │   │   └── {userId}
  │   │       ├── user_id: string
  │   │       ├── name: string  [DENORM]
  │   │       ├── role: enum (student | teacher)
  │   │       ├── joined_at: timestamp
  │   │       └── status: enum (active | left)
  │   │
  │   ├── subcollection: assigned_sets/
  │   │   └── {setId}
  │   │       ├── set_id: string
  │   │       ├── title: string  [DENORM]
  │   │       ├── assigned_at: timestamp
  │   │       ├── assigned_by: string (teacher_id)
  │   │       └── subcollection: progress/
  │   │           └── {userId}
  │   │               ├── user_id: string
  │   │               ├── status: enum (not_started | in_progress | completed)
  │   │               ├── learned_count: integer
  │   │               ├── unknown_count: integer
  │   │               ├── last_studied_at: timestamp
  │   │               └── studied_duration_sec: integer
  │   │
  │   └── subcollection: activities/
  │       └── {activityId}
  │           ├── id: string
  │           ├── type: enum (assignment_created | quiz_assigned | member_joined)
  │           ├── message: string
  │           ├── actor_id: string (user who triggered)
  │           ├── created_at: timestamp
  │           └── metadata: object (extra data per type)
  │
  └── //{More classrooms} ...
```

#### 4. quizzes/

```
quizzes/ (Root)
  ├── {quizId}
  │   ├── id: string
  │   ├── title: string
  │   ├── description: string
  │   ├── status: enum (draft | published)
  │   ├── source_set_id: string (reference to flashcard_sets/)
  │   ├── source_set_title: string  [DENORM]
  │   ├── teacher_id: string
  │   ├── created_at: timestamp
  │   ├── published_at: timestamp (nullable)
  │   │
  │   ├── subcollection: questions/
  │   │   └── {questionId}
  │   │       ├── id: string
  │   │       ├── card_id: string (reference to source set's flashcard)
  │   │       ├── question_text: string (front from flashcard)
  │   │       ├── order: integer
  │   │       ├── subcollection: options/
  │   │       │   └── {optionId}
  │   │       │       ├── id: string
  │   │       │       ├── text: string (back text or multiple choice)
  │   │       │       ├── is_correct: boolean
  │   │       │       └── order: integer
  │   │       └── subcollection: attempts/  [Alternative: move to parent]
  │   │           └── {attemptId}_{questionId}
  │   │               ├── attempt_id: string
  │   │               ├── question_id: string
  │   │               ├── selected_option_id: string (nullable if unanswered)
  │   │               ├── is_correct: boolean (nullable if unanswered)
  │   │               └── answered_at: timestamp
  │   │
  │   └── subcollection: attempts/
  │       └── {attemptId}
  │           ├── id: string
  │           ├── student_id: string
  │           ├── student_name: string  [DENORM]
  │           ├── classroom_id: string (nullable if not assigned)
  │           ├── status: enum (in_progress | submitted | expired)
  │           ├── started_at: timestamp
  │           ├── submitted_at: timestamp (nullable)
  │           ├── score: integer (0-100, only if submitted)
  │           ├── total_questions: integer
  │           ├── correct_count: integer
  │           ├── time_spent_sec: integer
  │           └── subcollection: answers/
  │               └── {questionId}
  │                   ├── question_id: string
  │                   ├── selected_option_id: string (nullable)
  │                   ├── is_correct: boolean (nullable)
  │                   └── answered_at: timestamp
  │
  └── //{More quizzes} ...
```

**Alternative Architecture for Quiz Attempts:**
Instead of `quizzes/{quizId}/attempts/{attemptId}`, store in a root `quiz_attempts/` collection:
```
quiz_attempts/
  ├── {attemptId}
  │   ├── id: string
  │   ├── quiz_id: string
  │   ├── student_id: string
  │   ├── classroom_id: string
  │   ├── status: enum
  │   ├── started_at, submitted_at, score, etc.
  │   └── subcollection: answers/
```
**Reason:** Allows independent queries on attempts (e.g., "all my attempts across all quizzes") without querying every quiz. **Use this approach for Memocard.**

#### 5. SQLite Schema (Local Cache)

Tables mirror Firestore structure; columns include `server_id`, `dirty_at`, `synced_at` for sync metadata:

```sql
-- Users (read-only local cache)
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE,
  name TEXT,
  role TEXT,
  status TEXT,
  avatar_url TEXT,
  created_at INTEGER,
  updated_at INTEGER,
  last_login_at INTEGER,
  synced_at INTEGER
);

-- FlashcardSets (user owns, can modify)
CREATE TABLE IF NOT EXISTS flashcard_sets (
  id TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  owner_id TEXT,
  visibility TEXT,
  card_count INTEGER,
  created_at INTEGER,
  updated_at INTEGER,
  dirty_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- Flashcards (belongs to set, read-only from Firestore)
CREATE TABLE IF NOT EXISTS flashcards (
  id TEXT PRIMARY KEY,
  set_id TEXT,
  front TEXT,
  back TEXT,
  image_path TEXT,
  audio_url TEXT,
  card_order INTEGER,
  created_at INTEGER,
  updated_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (set_id) REFERENCES flashcard_sets(id)
);

-- LearningSession (immutable after created)
CREATE TABLE IF NOT EXISTS learning_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  set_id TEXT,
  status TEXT,
  started_at INTEGER,
  ended_at INTEGER,
  cards_learned INTEGER,
  cards_unknown INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (set_id) REFERENCES flashcard_sets(id)
);

-- SessionCard (part of session)
CREATE TABLE IF NOT EXISTS session_cards (
  id TEXT PRIMARY KEY,
  session_id TEXT,
  card_id TEXT,
  front TEXT,
  back TEXT,
  status TEXT,
  answered_at INTEGER,
  card_order INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (session_id) REFERENCES learning_sessions(id),
  FOREIGN KEY (card_id) REFERENCES flashcards(id)
);

-- CardProgress (user's progress on a card)
CREATE TABLE IF NOT EXISTS card_progress (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  card_id TEXT,
  set_id TEXT,
  status TEXT,
  review_count INTEGER,
  last_reviewed_at INTEGER,
  dirty_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (card_id) REFERENCES flashcards(id),
  FOREIGN KEY (set_id) REFERENCES flashcard_sets(id)
);

-- Classroom
CREATE TABLE IF NOT EXISTS classrooms (
  id TEXT PRIMARY KEY,
  name TEXT,
  code TEXT UNIQUE,
  teacher_id TEXT,
  teacher_name TEXT,
  member_count INTEGER,
  created_at INTEGER,
  updated_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (teacher_id) REFERENCES users(id)
);

-- ClassMember (join table)
CREATE TABLE IF NOT EXISTS class_members (
  id TEXT PRIMARY KEY,
  classroom_id TEXT,
  user_id TEXT,
  name TEXT,
  role TEXT,
  joined_at INTEGER,
  status TEXT,
  synced_at INTEGER,
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- AssignedSet
CREATE TABLE IF NOT EXISTS assigned_sets (
  id TEXT PRIMARY KEY,
  classroom_id TEXT,
  set_id TEXT,
  title TEXT,
  assigned_at INTEGER,
  assigned_by TEXT,
  synced_at INTEGER,
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
  FOREIGN KEY (set_id) REFERENCES flashcard_sets(id)
);

-- AssignmentProgress
CREATE TABLE IF NOT EXISTS assignment_progress (
  id TEXT PRIMARY KEY,
  classroom_id TEXT,
  set_id TEXT,
  user_id TEXT,
  status TEXT,
  learned_count INTEGER,
  unknown_count INTEGER,
  last_studied_at INTEGER,
  studied_duration_sec INTEGER,
  dirty_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
  FOREIGN KEY (set_id) REFERENCES flashcard_sets(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ClassActivity (read-only, synced from Firestore)
CREATE TABLE IF NOT EXISTS class_activities (
  id TEXT PRIMARY KEY,
  classroom_id TEXT,
  type TEXT,
  message TEXT,
  actor_id TEXT,
  created_at INTEGER,
  metadata TEXT,
  synced_at INTEGER,
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id),
  FOREIGN KEY (actor_id) REFERENCES users(id)
);

-- Quiz
CREATE TABLE IF NOT EXISTS quizzes (
  id TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  status TEXT,
  source_set_id TEXT,
  source_set_title TEXT,
  teacher_id TEXT,
  created_at INTEGER,
  published_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (source_set_id) REFERENCES flashcard_sets(id),
  FOREIGN KEY (teacher_id) REFERENCES users(id)
);

-- QuizQuestion
CREATE TABLE IF NOT EXISTS quiz_questions (
  id TEXT PRIMARY KEY,
  quiz_id TEXT,
  card_id TEXT,
  question_text TEXT,
  question_order INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id),
  FOREIGN KEY (card_id) REFERENCES flashcards(id)
);

-- QuizOption
CREATE TABLE IF NOT EXISTS quiz_options (
  id TEXT PRIMARY KEY,
  question_id TEXT,
  text TEXT,
  is_correct INTEGER,
  option_order INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (question_id) REFERENCES quiz_questions(id)
);

-- QuizAttempt (immutable after submission)
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id TEXT PRIMARY KEY,
  quiz_id TEXT,
  student_id TEXT,
  student_name TEXT,
  classroom_id TEXT,
  status TEXT,
  started_at INTEGER,
  submitted_at INTEGER,
  score INTEGER,
  total_questions INTEGER,
  correct_count INTEGER,
  time_spent_sec INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id),
  FOREIGN KEY (student_id) REFERENCES users(id),
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
);

-- QuizAnswer (part of attempt)
CREATE TABLE IF NOT EXISTS quiz_answers (
  id TEXT PRIMARY KEY,
  attempt_id TEXT,
  question_id TEXT,
  selected_option_id TEXT,
  is_correct INTEGER,
  answered_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id),
  FOREIGN KEY (question_id) REFERENCES quiz_questions(id),
  FOREIGN KEY (selected_option_id) REFERENCES quiz_options(id)
);

-- FavoriteSet
CREATE TABLE IF NOT EXISTS favorite_sets (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  set_id TEXT,
  title TEXT,
  added_at INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (set_id) REFERENCES flashcard_sets(id)
);

-- QuizAssignment (join table: quiz -> classroom)
CREATE TABLE IF NOT EXISTS quiz_assignments (
  id TEXT PRIMARY KEY,
  quiz_id TEXT,
  classroom_id TEXT,
  assigned_at INTEGER,
  assigned_by TEXT,
  due_date INTEGER,
  synced_at INTEGER,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id),
  FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
);
```

### Queries That Firestore Handles Poorly

Firestore is document-based, not SQL. These queries are inefficient or impossible:

| Query | Problem | Workaround |
|-------|---------|-----------|
| "All public sets, sorted by creation date" | Cannot order by nested subcollection fields; would need to enumerate all sets | Add `public_sets/` denormalized collection or use ElasticSearch |
| "Users with most cards learned this week" | No aggregation functions; would need to scan all CardProgress records | Run a scheduled Cloud Function to compute weekly leaderboard |
| "Flashcards in a set sorted by difficulty" | Firestore can't compute "difficulty" from CardProgress; would need manual ranking | Add `difficulty` field to each flashcard, computed externally |
| "Count of quiz attempts per classroom per week" | No COUNT or GROUP BY | Compute in Cloud Function, store in classroom document |
| "Quiz results where score >= 80" | Cannot filter on computed fields (like score) easily | Pre-compute score on write, store as field |
| "All assignments not yet started by a student" | Requires joining assignments + progress + filtering missing records | Query progress docs; those missing = not started |

**Mitigation Strategy:**
1. For simple queries (single collection, filters, sorting by existing fields) — use Firestore queries
2. For complex aggregations — pre-compute in Cloud Functions, store results
3. For ad-hoc analytics — export to BigQuery (not in MVP scope)

---

## 6. Build Order & Dependency Graph

### Feature Module Dependencies

```
┌────────────────────────────────────────────┐
│  Phase 1: CORE/FOUNDATION                  │
│  (1 person, 3-4 days, serial)             │
│                                            │
│  • Firebase init, auth, Firestore setup   │
│  • SQLite schema, database service        │
│  • Riverpod shared providers              │
│  • Router, theme, widgets                 │
└─────────────────────────────────────────────┘
                    ▼
          ┌─────────┬─────────┬─────────┬─────────┐
          ▼         ▼         ▼         ▼         ▼
      ┌────────┐ ┌──────────────┐ ┌────────────┐ ┌─────────────┐ ┌──────┐
      │ Auth   │ │ Flashcard    │ │ Classroom  │ │ Learning    │ │ Quiz │
      │ (P1)   │ │ Set (P2)     │ │ (P4)       │ │ Mode (P3)   │ │ (P5) │
      │ 6 days │ │ 6 days       │ │ 6 days     │ │ 7 days      │ │ 8 days
      └────────┘ └──────────────┘ └────────────┘ └─────────────┘ └──────┘
           │            │              │              │            │
           └──┬──────────┴──────────────┴──────────────┴────────────┘
              │
         (Integration & QA)
              │
         Phase 2
```

### Dependency Constraints

```
Learning Mode depends on:
  ✓ Auth (user identity, role check)
  ✓ Flashcard Set (sets to learn from)
  ✓ Core (database, providers, router)

Classroom depends on:
  ✓ Auth (teacher/student roles)
  ✓ Flashcard Set (assign sets to classroom)
  ✓ Core (database, providers)

Quiz depends on:
  ✓ Auth (teacher creates, students submit)
  ✓ Flashcard Set (source of quiz questions)
  ✓ Classroom (optional, to assign to class)
  ✓ Core (database, providers)

Flashcard Set depends on:
  ✓ Auth (user owns sets)
  ✓ Core (database, providers)

Auth depends on:
  ✓ Core (Firebase, database, providers)
```

### Suggested Sequencing (5 Parallel + Integration)

**Weeks 1-2:**

| Week | Task | Owner | Duration | Blocker Resolution |
|------|------|-------|----------|-------------------|
| 1 | Phase 1: Core/Foundation | Lead (P1) | 4 days | All team waits here |
| 1 | Setup repo, CI/CD, Firestore project | Tech lead | 2 days | Parallel with Phase 1 |
| 2 | Auth module | P1 | 6 days | Can start after Phase 1 + day 1 |
| 2 | Flashcard Set module | P2 | 6 days | Can start after Phase 1 + day 1 |
| 2 | Learning Mode module | P3 | 7 days | Can start after Phase 1 + day 1, depends Auth + FlashcardSet |

**Weeks 3-4:**

| Week | Task | Owner | Duration | Notes |
|------|------|-------|----------|-------|
| 3 | Classroom module | P4 | 6 days | Can start after Phase 1 + day 1, depends Auth + FlashcardSet |
| 3 | Quiz module | P5 | 8 days | Can start after Phase 1 + day 1, depends Auth + FlashcardSet (optionally Classroom) |
| 4 | Integration & testing | All | 3 days | E2E tests, cross-feature testing |
| 4 | Bug fixes & polish | All | 2 days | Stability before demo |

**Critical Path:**
- Phase 1: 4 days (serial)
- Longest feature (Quiz): 8 days
- **Total: 12-13 days if no blocking issues**

### Implementation Order Strategy

**Stagger starts to minimize blocking:**

1. **Day 1-4:** P1 builds Phase 1 core
2. **Day 5:** P1 starts Auth; P2 starts Flashcard Set (once Phase 1 done)
3. **Day 6:** P3 waits for Auth + FlashcardSet, starts Learning Mode skeleton
4. **Day 7:** P4, P5 start Classroom and Quiz in parallel
5. **Day 10+:** Integrate, test, ship

**Parallel dependencies must be managed via feature interfaces:**
- FlashcardSet module defines `FlashcardSetRepository` interface
- Learning module imports only the interface (not concrete impl)
- Both can develop in parallel; concrete impl injected at runtime via Riverpod

---

## 7. Git Workflow for Multi-Developer Coordination

### Branch Strategy

```
main (production-ready)
  └─ develop (integration branch)
      ├─ feature/auth-login
      ├─ feature/auth-admin
      ├─ feature/flashcard-crud
      ├─ feature/learning-session
      ├─ feature/classroom-management
      └─ feature/quiz-attempts
```

### Commit Message Convention

```
<type>: <scope> - <subject>

<body>

Affects: auth, flashcard_set, learning, classroom, quiz
```

Where:
- `type`: `feat`, `fix`, `refactor`, `test`, `docs`
- `scope`: Feature module (e.g., `auth`, `flashcard_set`)
- `subject`: What changed (present tense)
- `Affects`: Which modules are impacted (comma-separated)

### Conflict Prevention

1. **Each developer owns their feature module folder entirely.**
   - No commits to other module's `features/*/` folder
   - All edits to `core/` require lead dev review

2. **Shared files only in core/**
   - If Person 2 needs to modify `lib/core/providers/auth_state_provider.dart`, they raise a PR to core before merging to develop

3. **Use dependency injection, not direct imports.**
   - `features/learning/` imports `features/learning/data/repositories/learning_repository.dart` (own)
   - `features/learning/` imports `core/providers/auth_state_provider.dart` (shared, read-only)
   - Never imports `features/flashcard_set/` directly; use via Riverpod provider interface

4. **Riverpod providers are scoped per feature.**
   - `features/learning/presentation/providers/` is internal to learning
   - Core providers only in `core/providers/`

---

## 8. Communication & Data Flow Diagram

### High-Level Data Flow (Example: Start Learning Session)

```
┌──────────────┐
│   UI Layer   │ "Start Learning with Set X"
│ (learning_   │ (user taps button)
│  card_page)  │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────┐
│   Riverpod Provider                  │
│ (active_session_provider)            │
│ Calls: startLearning(setId)          │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│   UseCase                            │
│ (StartLearningUseCase)               │
│ Validates user, set exists, offline? │
└──────┬───────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│   Repository                         │
│ (LearningRepositoryImpl)              │
│ 1. Create session in Firestore       │
│ 2. Fetch flashcards from cache/remote
│ 3. Cache session + cards locally     │
└──────┬───────────────────────────────┘
       │
       ├─────────────────────┬──────────────────────┐
       ▼                     ▼                      ▼
┌─────────────┐       ┌──────────────┐        ┌──────────────┐
│RemoteDS:    │       │LocalDS:      │        │LocalDS:      │
│Firestore    │       │SQLite (Read) │        │SQLite(Write) │
│             │       │              │        │              │
│Set/Get      │       │Query cache   │        │upsertSession │
│LearningSessl       │Get flashcards│        │upsertCards   │
└─────────────┘       └──────────────┘        └──────────────┘
       │                                           │
       └───────────────────────────────────────────┘
              (Success → update UI)
                       │
                       ▼
          ┌─────────────────────────┐
          │ UI updates with session │
          │ Cards ready to study    │
          └─────────────────────────┘
```

### Offline Scenario

```
User starts learning (NO INTERNET):
  1. UI calls provider → startLearning(setId)
  2. Repository tries Firestore.createSession() → fails offline
  3. Firestore SDK queues write locally (automatic)
  4. Repository falls back: SQLite.getFlashcards(setId) → success
  5. UI renders session with cached cards
  6. When online: Firestore syncs queued session creation
```

---

## Component Boundaries (What Talks to What)

```
┌─────────────────────────────────────────────────────────┐
│  Presentation Layer (UI Pages + Widgets)                │
│  • Only reads from Riverpod providers                   │
│  • Calls notifier methods (via providers) to mutate     │
│  • Never imports data sources or repositories directly  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  Riverpod Provider Layer (State Management)             │
│  • FutureProvider for one-time fetches                  │
│  • StreamProvider for real-time subscriptions           │
│  • AsyncNotifierProvider for mutations                  │
│  • Injects repositories via constructor                │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  Domain Layer (UseCase / Repository Interfaces)         │
│  • Business logic only (no Flutter, no Firestore)       │
│  • Repository interfaces define contracts              │
│  • UseCases orchestrate logic                           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  Data Layer (Repository Impl + DataSources)             │
│  • Combines RemoteDataSource + LocalDataSource          │
│  • Handles offline/online logic                         │
│  • Syncs cache with remote                              │
└─────────────────────────────────────────────────────────┘
       │                                      │
       ▼                                      ▼
┌──────────────────┐              ┌──────────────────────┐
│RemoteDataSource  │              │LocalDataSource       │
│(Firestore calls) │              │(SQLite queries)      │
│                  │              │                      │
│• Query           │              │• Query by primary key
│• Listen (stream) │              │• Bulk insert/update  │
│• Write/Update    │              │• Delete              │
│• Batch ops       │              │• Mark dirty/synced   │
└──────────────────┘              └──────────────────────┘
       │                                      │
       ▼                                      ▼
   Firebase                             sqflite_common_ffi
   Firestore                            (Android + Windows)
```

---

## 9. Scalability Considerations

### At 100 Users
- Firestore: All root collections queried per user
- SQLite: Single device, no scaling needed
- Sync: Pull on app launch, stream subscriptions
- Problem: N+1 queries when listing classroom members

### At 10K Users
- Firestore: Add composite indexes for common queries (classroom + date)
- SQLite: Consider pagination for large lists
- Sync: Consider background sync service (periodic pull)
- Problem: Denormalized fields go stale (user name changes, not propagated)

### At 1M Users
- Firestore: Use Datastore for relational queries; move to PostgreSQL
- SQLite: Not a bottleneck (local device)
- Sync: Implement delta sync (only changed records)
- Problem: Firestore pricing becomes prohibitive; switch to self-hosted

**Recommendation for MVP (Memocard):** Optimize for 10K users. At 100 users, performance is acceptable. If scaling beyond 10K, re-architect data layer to Cloud SQL / Realtime Database.

---

## 10. Security & Firebase Rules

### Default Rules (Phase 1)

```javascript
// firestore.rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ===== USERS =====
    match /users/{userId} {
      allow read: if request.auth.uid == userId || 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow write: if request.auth.uid == userId ||
                      (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
                       request.resource.data.role in ['student', 'teacher', 'admin']);
      allow delete: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      match /flashcard_sets/{setId} {
        allow read: if request.auth.uid == userId;
        allow write: if request.auth.uid == userId;
      }
      match /learning_sessions/{sessionId} {
        allow read: if request.auth.uid == userId;
        allow write: if request.auth.uid == userId;
      }
      // ... other subcollections
    }
    
    // ===== FLASHCARD_SETS =====
    match /flashcard_sets/{setId} {
      allow read: if resource.data.visibility == 'public' ||
                     resource.data.owner_id == request.auth.uid;
      allow create: if request.auth.uid != null && 
                       request.resource.data.owner_id == request.auth.uid;
      allow update, delete: if resource.data.owner_id == request.auth.uid;
      
      match /flashcards/{cardId} {
        allow read: if resource.data.visibility == 'public' ||
                       get(/databases/$(database)/documents/flashcard_sets/$(setId)).data.owner_id == request.auth.uid;
        allow write: if get(/databases/$(database)/documents/flashcard_sets/$(setId)).data.owner_id == request.auth.uid;
      }
    }
    
    // ===== CLASSROOMS =====
    match /classrooms/{classroomId} {
      allow read: if exists(/databases/$(database)/documents/classrooms/$(classroomId)/members/$(request.auth.uid)) ||
                     get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacher_id == request.auth.uid;
      allow create: if request.auth.uid != null &&
                       request.resource.data.teacher_id == request.auth.uid;
      allow update: if get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacher_id == request.auth.uid;
      allow delete: if get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacher_id == request.auth.uid;
      
      match /members/{userId} {
        allow read: if request.auth.uid == userId ||
                       get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacher_id == request.auth.uid;
        allow create: if request.auth.uid == userId;
        allow delete: if get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacher_id == request.auth.uid;
      }
      
      match /assigned_sets/{setId} {
        allow read: if exists(/databases/$(database)/documents/classrooms/$(classroomId)/members/$(request.auth.uid));
        allow create, update, delete: if get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacher_id == request.auth.uid;
      }
    }
    
    // ===== QUIZZES =====
    match /quizzes/{quizId} {
      allow read: if resource.data.status == 'published' ||
                     resource.data.teacher_id == request.auth.uid;
      allow create, update: if request.auth.uid != null &&
                               request.resource.data.teacher_id == request.auth.uid;
      allow delete: if resource.data.teacher_id == request.auth.uid &&
                       resource.data.status == 'draft';
      
      match /questions/{questionId} {
        allow read: if get(/databases/$(database)/documents/quizzes/$(quizId)).data.status == 'published' ||
                       get(/databases/$(database)/documents/quizzes/$(quizId)).data.teacher_id == request.auth.uid;
        allow write: if get(/databases/$(database)/documents/quizzes/$(quizId)).data.teacher_id == request.auth.uid;
      }
      
      match /attempts/{attemptId} {
        allow read: if resource.data.student_id == request.auth.uid ||
                       get(/databases/$(database)/documents/quizzes/$(quizId)).data.teacher_id == request.auth.uid;
        allow create: if request.auth.uid != null &&
                        request.resource.data.student_id == request.auth.uid;
        allow update: if resource.data.student_id == request.auth.uid &&
                         resource.data.status == 'in_progress';
      }
    }
  }
}
```

---

## Summary: Architecture Decisions at a Glance

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| **Folder Structure** | Feature-first (vertical slice) with shared core | Enables 5 parallel developers with minimal conflicts |
| **Repository Pattern** | Dual data source (Firestore + SQLite) | Meets "offline-first cache" + "Firestore source of truth" requirements |
| **Read Path** | Cache-first (SQLite → Firestore fallback) | Fast UX when offline; fresh data when online |
| **Write Path** | Firestore-primary (SDK queues offline) | Single source of truth; sync on reconnect |
| **State Management** | Riverpod (FutureProvider, StreamProvider, AsyncNotifierProvider) | Required by spec; clean provider organization per feature |
| **Shared Core** | Immutable phase 1 (auth, DB, providers, router, theme) | Prevents 5-way conflicts; everyone builds on same foundation |
| **Firestore Schema** | Collections + subcollections + denormalization | Maps relational ERD; denormalize for query performance |
| **SQLite Schema** | Mirrors Firestore + sync metadata (dirty_at, synced_at) | Enables offline caching and conflict detection |
| **Build Order** | Phase 1 (core) → 5 features in parallel → integrate | Critical path ~12-13 days for MVP |
| **Security** | Firestore rules by role + ownership | Teachers own classrooms; users own sets; admins override |

---

## Sources

- [Flutter Project Structure: Feature-first or Layer-first?](https://codewithandrea.com/articles/flutter-project-structure/)
- [Guide to app architecture](https://docs.flutter.dev/app-architecture/guide)
- [Scalable Folder Structure for Flutter: Feature-First with Layered Approach](https://medium.com/@avendrasingh.work/scalable-folder-structure-for-flutter-feature-first-with-layered-approach-0ca3fb9c292b)
- [Offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
- [Implementing a repository pattern in Flutter](https://blog.logrocket.com/implementing-repository-pattern-flutter/)
- [Flutter App Architecture with Riverpod: An Introduction](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)
- [Firestore Data Model: An Easy Guide](https://hevodata.com/learn/firestore-data-model/)
- [How to Design Firestore Data Models for Complex Many-to-Many Relationships](https://oneuptime.com/blog/post/2026-02-17-how-to-design-firestore-data-models-for-complex-many-to-many-relationships/view)
- [Modeling Relational Data in NoSQL Firestore in Firebase](https://ayeshaiq.hashnode.dev/modeling-relational-data-in-nosql-firestore)
- [Scaling Flutter development: UI composition in a multi-team setup](https://blog.funda.nl/scaling-flutter-development-ui-composition-in-a-multi-team-setup/)
- [Multiple Team Branching | Flutter Inner Source](https://innersource.flutter.com/sdlc/multiple-teams/branching/)
- [Cloud Firestore Transactions and Batched Writes Flutter](https://medium.com/@debnathakash8/firestore-transactions-batchedwrites-with-flutter-e675c941572f)
- [Transactions and batched writes | Firestore | Firebase](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [Building Offline-First Applications with SQLite and Sync Strategies](https://www.sqliteforum.com/p/building-offline-first-applications)
- [Riverpod](https://riverpod.dev/)
- [Providers | Riverpod](https://riverpod.dev/docs/concepts2/providers)
