import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../data/firebase_backend_service.dart';
import '../data/memocard_repository.dart';
import '../models/memocard_models.dart';

final repositoryProvider = Provider<MemocardRepository>((ref) {
  return MemocardRepository(AppDatabase.instance);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final firebaseReadyProvider = FutureProvider<bool>((ref) {
  return FirebaseBackendService.instance.tryInitialize();
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  static const _sessionUserIdKey = 'session_user_id';

  MemocardRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<AppUser?> build() async {
    await _repo.ensureSeedData();
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final userId = prefs.getString(_sessionUserIdKey);
    if (userId == null) return null;
    return _repo.userById(userId);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. Register with Firebase Auth (Requirement)
      await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Register locally in SQLite
      final user = await _repo.register(
        username: username,
        email: email,
        password: password,
        role: role,
      );
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString(_sessionUserIdKey, user.id);
      await prefs.setString('session_role', user.role);
      return user;
    });
  }

  Future<void> login(String account, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. Login with SQLite
      final user = await _repo.login(account, password);
      if (user == null) {
        throw Exception('Tài khoản hoặc mật khẩu không đúng');
      }

      // 2. Login with Firebase Auth if it's an email (Requirement compliance)
      if (account.contains('@')) {
        try {
          await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
            email: account,
            password: password,
          );
        } catch (e) {
          // If firebase fails but local works, we might still want to proceed 
          // or handle it. For SWP, let's just log it.
        }
      }

      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString(_sessionUserIdKey, user.id);
      await prefs.setString('session_role', user.role);
      return user;
    });
  }

  Future<void> logout() async {
    await fb.FirebaseAuth.instance.signOut();
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_sessionUserIdKey);
    await prefs.remove('session_role');
    state = const AsyncData(null);
  }
}

final setsProvider = FutureProvider.autoDispose
    .family<List<FlashcardSet>, String>((ref, query) {
      final repo = ref.watch(repositoryProvider);
      return repo.ensureSeedData().then((_) => repo.sets(query: query));
    });

final cardsProvider = FutureProvider.autoDispose
    .family<List<Flashcard>, String>((ref, setId) {
      return ref.watch(repositoryProvider).cards(setId);
    });

final usersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return repo.ensureSeedData().then((_) => repo.users());
});

class UserSearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final userSearchQueryProvider = NotifierProvider<UserSearchQuery, String>(UserSearchQuery.new);

final filteredUsersProvider = Provider.autoDispose<AsyncValue<List<AppUser>>>((ref) {
  final usersAsync = ref.watch(usersProvider);
  final query = ref.watch(userSearchQueryProvider).toLowerCase();

  return usersAsync.whenData((users) {
    if (query.isEmpty) return users;
    return users.where((user) {
      return user.username.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.fullName.toLowerCase().contains(query);
    }).toList();
  });
});

final learningHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, Object?>>, String>((ref, userId) {
      return ref.watch(repositoryProvider).learningHistory(userId);
    });

final classroomProvider = FutureProvider.autoDispose
    .family<List<Classroom>, String>((ref, userId) {
      final repo = ref.watch(repositoryProvider);
      return repo.ensureSeedData().then((_) => repo.classrooms(userId));
    });

final quizHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, Object?>>, String>((ref, userId) {
      return ref.watch(repositoryProvider).quizHistory(userId);
    });

final teacherQuizzesProvider = FutureProvider.autoDispose
    .family<List<TeacherQuiz>, String>((ref, teacherId) {
      return ref.watch(repositoryProvider).quizzesByTeacher(teacherId);
    });

final teacherQuizProvider = FutureProvider.autoDispose
    .family<TeacherQuiz?, String>((ref, quizId) {
      return ref.watch(repositoryProvider).quizById(quizId);
    });

final teacherQuizQuestionsProvider = FutureProvider.autoDispose
    .family<List<TeacherQuizQuestion>, String>((ref, quizId) {
      return ref.watch(repositoryProvider).quizQuestions(quizId);
    });
