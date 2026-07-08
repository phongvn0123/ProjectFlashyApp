import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Gốc của ứng dụng: cấu hình [MaterialApp], theme và router.
///
/// Dùng `MaterialApp.router` để điều hướng bằng `go_router`
/// (khai báo trong `core/router/app_router.dart`).
class FlashlyApp extends StatelessWidget {
  const FlashlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // App theo design language Apple sáng/parchment — chưa làm dark mode.
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
