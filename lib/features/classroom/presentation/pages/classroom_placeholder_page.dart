import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';

class ClassroomPlaceholderPage extends ConsumerWidget {
  const ClassroomPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref
        .watch(authControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final canCreateClass = user?.role == 'teacher' || user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Lớp học')),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  _showClassDialog(context, ref, user.id, user.role),
              icon: Icon(canCreateClass ? Icons.add : Icons.login),
              label: Text(canCreateClass ? 'Tạo lớp' : 'Tham gia'),
            ),
      body: user == null
          ? const Center(child: Text('Đăng nhập để xem lớp học.'))
          : ref
                .watch(classroomProvider(user.id))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(child: Text('$error')),
                  data: (classes) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        canCreateClass ? 'Lớp đang dạy' : 'Lớp đã tham gia',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        canCreateClass
                            ? 'Vai trò ${user.role}: được tạo và quản lý lớp.'
                            : 'Vai trò học sinh: chỉ được tham gia lớp bằng mã.',
                      ),
                      const SizedBox(height: 12),
                      if (classes.isEmpty)
                        const Card(
                          child: ListTile(title: Text('Chưa có lớp học nào')),
                        ),
                      for (final item in classes)
                        Card(
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text('Mã lớp: ${item.joinCode}'),
                            trailing: Icon(
                              item.isJoinEnabled ? Icons.lock_open : Icons.lock,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _showClassDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String role,
  ) async {
    final canCreateClass = role == 'teacher' || role == 'admin';
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(canCreateClass ? 'Tạo lớp học' : 'Nhập mã lớp'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: canCreateClass ? 'Tên lớp' : 'Mã 6 chữ số',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              if (canCreateClass) {
                await ref
                    .read(repositoryProvider)
                    .createClass(userId, controller.text);
              } else {
                await ref
                    .read(repositoryProvider)
                    .joinClass(userId, controller.text);
              }
              ref.invalidate(classroomProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}
