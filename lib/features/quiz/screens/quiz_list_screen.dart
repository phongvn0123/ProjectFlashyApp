import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../providers/quiz_providers.dart';
import '../widgets/quiz_list_tile.dart';

/// Màn hình ghép các widget và lắng nghe Riverpod state.
///
/// Screen không chứa SQL, Firebase hay câu lệnh backend.
class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzes = ref.watch(quizListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz / Test')),
      body: quizzes.when(
        loading: () => const LoadingView(message: 'Đang tải danh sách quiz…'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(quizListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(
              message: 'Chưa có Quiz/Test.',
              icon: Icons.quiz_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(quizListProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(Sp.md),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return QuizListTile(
                  quiz: items[index],
                  onTap: () {
                    // TODO(quiz): điều hướng đến màn chi tiết Quiz/Test.
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
