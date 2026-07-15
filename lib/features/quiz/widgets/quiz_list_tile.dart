import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/quiz_model.dart';

/// Widget nhỏ chỉ hiển thị một Quiz; không truy cập database hay provider.
class QuizListTile extends StatelessWidget {
  const QuizListTile({super.key, required this.quiz, this.onTap});

  final QuizModel quiz;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Sp.sm),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: quiz.isPublished
              ? AppColors.primary
              : AppColors.parchment,
          foregroundColor: quiz.isPublished
              ? Colors.white
              : AppColors.inkMuted80,
          child: const Icon(Icons.quiz_outlined),
        ),
        title: Text(quiz.title),
        subtitle: Text(
          '${quiz.questionCount} câu hỏi • ${_statusLabel(quiz.status)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'published' => 'Đã công bố',
    'draft' => 'Bản nháp',
    _ => status,
  };
}
