import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Màn hình giữ chỗ cho các route chưa code.
///
/// `app_router.dart` trỏ tạm các màn chưa làm vào đây để app vẫn chạy & điều
/// hướng được. Khi xây màn thật theo `SCREENS.md` thì thay vào router.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined,
                  size: 48, color: AppColors.inkMuted48),
              const SizedBox(height: Sp.md),
              Text('“$title” — sắp có',
                  style: AppText.bodyStrong(context), textAlign: TextAlign.center),
              const SizedBox(height: Sp.xxs),
              Text('Màn hình này sẽ được dựng theo SCREENS.md.',
                  style: AppText.caption(context)?.copyWith(color: AppColors.inkMuted48),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
