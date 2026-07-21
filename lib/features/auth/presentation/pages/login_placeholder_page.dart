import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/routes.dart';

class LoginPlaceholderPage extends ConsumerStatefulWidget {
  const LoginPlaceholderPage({super.key});

  @override
  ConsumerState<LoginPlaceholderPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPlaceholderPage> {
  final _account = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'student';
  bool _register = false;

  @override
  void dispose() {
    _account.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = ref.read(authControllerProvider.notifier);
    if (_register) {
      await auth.register(
        username: _username.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      );
    } else {
      await auth.login(_account.text, _password.text);
    }
    if (!mounted) return;
    final current = ref
        .read(authControllerProvider)
        .maybeWhen(data: (user) => user, orElse: () => null);
    if (current != null) context.go(kHomeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Memocard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _register ? 'Đăng ký tài khoản' : 'Đăng nhập',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Đăng nhập')),
              ButtonSegment(value: true, label: Text('Đăng ký')),
            ],
            selected: {_register},
            onSelectionChanged: (value) =>
                setState(() => _register = value.first),
          ),
          const SizedBox(height: 16),
          if (_register) ...[
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Vai trò'),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Học sinh')),
                DropdownMenuItem(value: 'teacher', child: Text('Giáo viên')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'student'),
            ),
          ] else
            TextField(
              controller: _account,
              decoration: const InputDecoration(
                labelText: 'Email hoặc username',
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            child: Text(
              auth.isLoading
                  ? 'Đang xử lý...'
                  : (_register ? 'Tạo tài khoản' : 'Đăng nhập'),
            ),
          ),
          if (auth.hasError) ...[
            const SizedBox(height: 12),
            Text(
              '${auth.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Text('Tài khoản mẫu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _DemoLoginButton(
            label: 'Học sinh',
            username: 'student',
            onPressed: auth.isLoading
                ? null
                : () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .login('student', '123456');
                    if (context.mounted) context.go(kHomeRoute);
                  },
          ),
          _DemoLoginButton(
            label: 'Giáo viên',
            username: 'teacher',
            onPressed: auth.isLoading
                ? null
                : () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .login('teacher', '123456');
                    if (context.mounted) context.go(kHomeRoute);
                  },
          ),
          _DemoLoginButton(
            label: 'Quản trị',
            username: 'admin',
            onPressed: auth.isLoading
                ? null
                : () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .login('admin', '123456');
                    if (context.mounted) context.go(kHomeRoute);
                  },
          ),
        ],
      ),
    );
  }
}

class _DemoLoginButton extends StatelessWidget {
  const _DemoLoginButton({
    required this.label,
    required this.username,
    required this.onPressed,
  });

  final String label;
  final String username;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.account_circle_outlined),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text('$label - $username / 123456'),
        ),
      ),
    );
  }
}
