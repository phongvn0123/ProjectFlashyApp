import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/routes.dart';

class ProfilePlaceholderPage extends ConsumerWidget {
  const ProfilePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(authControllerProvider);
                    context.go(kLoginRoute);
                  },
                  child: const Text('Quay lại Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return _SignedOut(onLogin: () => context.go(kLoginRoute));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 36,
                child: Text(user.username.substring(0, 1).toUpperCase()),
              ),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(user.email, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Username'),
                      trailing: Text(user.username),
                    ),
                    ListTile(
                      title: const Text('Vai trò'),
                      trailing: Text(user.role),
                    ),
                    ListTile(
                      title: const Text('Trạng thái'),
                      trailing: Text(user.status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push(kEditProfileRoute),
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa hồ sơ'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go(kLoginRoute);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
              if (user.role == 'admin') ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Quản trị hệ thống',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  title: const Text('Quản lý người dùng'),
                  subtitle: const Text('Xem danh sách, tìm kiếm, khóa/xóa tài khoản'),
                  trailing: const Icon(Icons.chevron_right),
                  tileColor: Colors.orange.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => context.push(kAdminUsersRoute),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Bạn cần đăng nhập để dùng Memocard.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onLogin, child: const Text('Đăng nhập')),
          ],
        ),
      ),
    );
  }
}
