import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/service_providers.dart';
import '../data/quiz_model.dart';
import '../data/quiz_repository.dart';
import '../services/quiz_service.dart';

/// Provider chỉ làm nhiệm vụ dependency injection và quản lý state cho UI.
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(
    ref.watch(localDbServiceProvider),
    ref.watch(apiServiceProvider),
  );
});

final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService(ref.watch(quizRepositoryProvider));
});

final quizListProvider = FutureProvider.autoDispose<List<QuizModel>>((ref) {
  return ref.watch(quizServiceProvider).loadQuizzes();
});
