import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/app_exception.dart';

/// Trạng thái lỗi dùng chung — icon + thông báo + nút "Thử lại".
///
/// Dùng cho nhánh `error` của `AsyncValue.when(...)`. Nếu truyền [error]
/// là [AppException] thì lấy đúng message thân thiện; còn lại fallback chung.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.error,
    this.message,
    this.onRetry,
  });

  final Object? error;
  final String? message;
  final VoidCallback? onRetry;

  String _resolveMessage() {
    if (message != null) return message!;
    final err = error;
    if (err is AppException) return err.message;
    return AppStrings.genericError;
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: Sp.md),
            Text(
              _resolveMessage(),
              textAlign: TextAlign.center,
              style: AppText.body(context)?.copyWith(color: AppColors.inkMuted80),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Sp.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );

    // Canh giữa như cũ khi đủ chỗ; nếu chiều cao bị giới hạn quá nhỏ (màn nhỏ)
    // thì cho phép cuộn để không tràn — không đổi giao diện.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) return content;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
