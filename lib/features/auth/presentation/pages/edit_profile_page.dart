import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pwdController;
  final _confirmPwdController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    _nameController = TextEditingController(text: user?.fullName);
    _pwdController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final repo = ref.read(repositoryProvider);
    
    try {
      // UC05: Cập nhật hồ sơ
      await repo.updateProfile(
        userId: user.id, 
        fullName: _nameController.text.trim(),
      );
      
      // UC06: Đổi mật khẩu (nếu có nhập)
      if (_pwdController.text.isNotEmpty) {
        await repo.changePassword(user.id, _pwdController.text);
      }

      // Refresh user state
      ref.invalidate(authControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                hintText: 'Nhập họ tên đầy đủ của bạn',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ tên';
                if (value.trim().length < 2) return 'Tên quá ngắn';
                return null;
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Thay đổi mật khẩu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Để trống nếu bạn không muốn thay đổi mật khẩu hiện tại',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pwdController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length < 6) return 'Mật khẩu mới phải từ 6 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPwdController,
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: Icon(Icons.lock_reset),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_pwdController.text.isNotEmpty) {
                  if (value != _pwdController.text) return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cập nhật ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
