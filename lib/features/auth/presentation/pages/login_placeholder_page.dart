import 'package:flutter/material.dart';

/// Placeholder for the `/auth/login` route, outside the 5-tab shell.
///
/// No logic yet — Phase 2 replaces this with real Firebase Auth
/// login/registration UI.
class LoginPlaceholderPage extends StatelessWidget {
  const LoginPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: const Center(child: Text('Đăng nhập — sắp ra mắt')),
    );
  }
}
