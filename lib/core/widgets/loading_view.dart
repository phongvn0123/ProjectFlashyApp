import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Trạng thái loading dùng chung — spinner màu primary + dòng mô tả (tuỳ chọn).
///
/// Dùng cho nhánh `loading` của `AsyncValue.when(...)`.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: Sp.md),
            Text(
              message!,
              style: AppText.caption(context)?.copyWith(color: AppColors.inkMuted48),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty-state dùng chung: icon mờ + 1 dòng mô tả + 1 CTA (tuỳ chọn).
///
/// Khớp mục "Trạng thái rỗng" trong SCREENS §15.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.inkMuted48),
            const SizedBox(height: Sp.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(context)?.copyWith(color: AppColors.inkMuted80),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Sp.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
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
