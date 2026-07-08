import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/error_view.dart';
import '../core/widgets/loading_view.dart';

/// Màn DEV: trưng bày các widget/token dùng chung để kiểm tra nhanh phần core.
///
/// KHÔNG thuộc luồng sản phẩm — xoá (cùng route `devShowcase`) khi UI thật xong.
class CoreShowcaseScreen extends StatefulWidget {
  const CoreShowcaseScreen({super.key});

  @override
  State<CoreShowcaseScreen> createState() => _CoreShowcaseScreenState();
}

class _CoreShowcaseScreenState extends State<CoreShowcaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form hợp lệ ✓ (demo AppButton.loading)')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Core — Shared widgets')),
      body: ListView(
        padding: const EdgeInsets.all(Sp.lg),
        children: [
          _section(context, 'Typography'),
          Text('Hero display', style: AppText.hero(context)),
          Text('Display large', style: AppText.displayLg(context)),
          Text('Display medium', style: AppText.displayMd(context)),
          Text('Tagline', style: AppText.tagline(context)),
          Text('Body strong', style: AppText.bodyStrong(context)),
          Text('Body 17px — đây là đoạn văn thường.', style: AppText.body(context)),
          Text('Caption 14px muted',
              style: AppText.caption(context)?.copyWith(color: AppColors.inkMuted48)),

          _section(context, 'AppTextField + Validators'),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  hint: 'ban@email.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: Sp.sm),
                AppTextField(
                  controller: _password,
                  label: 'Mật khẩu',
                  hint: '••••••',
                  obscure: true,
                  validator: Validators.password,
                ),
              ],
            ),
          ),

          _section(context, 'AppButton (nhấn để thấy scale 0.95)'),
          AppButton(label: 'Primary — Kiểm tra form', loading: _loading, onPressed: _submit),
          const SizedBox(height: Sp.sm),
          AppButton(
              label: 'Secondary (ghost)',
              variant: AppButtonVariant.secondary,
              icon: Icons.add,
              onPressed: () {}),
          const SizedBox(height: Sp.sm),
          AppButton(
              label: 'Danger — Xoá',
              variant: AppButtonVariant.danger,
              onPressed: () {}),
          const SizedBox(height: Sp.sm),
          AppButton(
              label: 'Disabled', onPressed: null),

          _section(context, 'Loading / Empty / Error'),
          SizedBox(height: 120, child: const LoadingView(message: 'Đang tải…')),
          const Divider(),
          SizedBox(
            height: 200,
            child: EmptyView(
              icon: Icons.favorite_border,
              message: 'Bạn chưa lưu bộ thẻ nào',
              actionLabel: 'Khám phá thư viện',
              onAction: () {},
            ),
          ),
          const Divider(),
          SizedBox(
            height: 200,
            child: ErrorView(
              message: 'Không tải được dữ liệu. Kiểm tra kết nối mạng.',
              onRetry: () {},
            ),
          ),
          const SizedBox(height: Sp.xl),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: Sp.xl, bottom: Sp.sm),
        child: Text(title, style: AppText.tagline(context)),
      );
}
