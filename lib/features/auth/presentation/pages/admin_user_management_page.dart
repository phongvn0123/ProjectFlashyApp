import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';

class AdminUserManagementPage extends ConsumerWidget {
  const AdminUserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(filteredUsersProvider);
    final searchController = TextEditingController(
      text: ref.read(userSearchQueryProvider),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    ref.read(userSearchQueryProvider.notifier).setQuery('');
                  },
                ),
              ),
              onChanged: (value) {
                ref.read(userSearchQueryProvider.notifier).setQuery(value);
              },
            ),
          ),
        ),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Không tìm thấy người dùng nào.'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final isMe = ref.read(authControllerProvider).value?.id == user.id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(user.role),
                  child: Text(
                    user.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.fullName.isEmpty ? user.username : user.fullName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    Row(
                      children: [
                        _StatusChip(status: user.status),
                        const SizedBox(width: 8),
                        Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(user.role),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: isMe
                    ? const Chip(label: Text('Bạn'))
                    : PopupMenuButton<String>(
                        onSelected: (value) => _handleAction(context, ref, value, user),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit_role',
                            child: ListTile(
                              leading: Icon(Icons.badge),
                              title: Text('Đổi vai trò'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: ListTile(
                              leading: Icon(user.status == 'active' ? Icons.block : Icons.check_circle),
                              title: Text(user.status == 'active' ? 'Khóa tài khoản' : 'Mở tài khoản'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reset_pwd',
                            child: ListTile(
                              leading: Icon(Icons.lock_reset),
                              title: Text('Reset mật khẩu'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Xóa người dùng', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action, dynamic user) async {
    final repo = ref.read(repositoryProvider);

    switch (action) {
      case 'edit_role':
        _showRoleDialog(context, ref, user);
        break;
      case 'toggle_status':
        final newStatus = user.status == 'active' ? 'banned' : 'active';
        await repo.updateUserStatus(user.id, newStatus);
        ref.invalidate(usersProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã ${newStatus == 'active' ? 'mở' : 'khóa'} tài khoản ${user.username}')),
          );
        }
        break;
      case 'reset_pwd':
        _showResetPwdDialog(context, ref, user);
        break;
      case 'delete':
        _showDeleteConfirm(context, ref, user);
        break;
    }
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đổi vai trò: ${user.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['student', 'teacher', 'admin'].map((role) {
            return RadioListTile<String>(
              title: Text(role == 'admin' ? 'Admin' : (role == 'teacher' ? 'Giáo viên' : 'Học sinh')),
              value: role,
              groupValue: user.role,
              onChanged: (value) async {
                if (value != null) {
                  await ref.read(repositoryProvider).updateUserRole(user.id, value);
                  ref.invalidate(usersProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetPwdDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final controller = TextEditingController(text: '123456');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset mật khẩu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(repositoryProvider).changePassword(user.id, controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật mật khẩu mới')),
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng ${user.username}? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(repositoryProvider).deleteUser(user.id);
              ref.invalidate(usersProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa người dùng')),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? Colors.green : Colors.red, width: 0.5),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Đã khóa',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
