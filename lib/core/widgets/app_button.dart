import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kiểu nút theo DESIGN-apple.md.
enum AppButtonVariant {
  /// Nền Action Blue, chữ trắng — hành động chính.
  primary,

  /// Pill viền hairline, chữ primary — hành động phụ (ghost).
  secondary,

  /// Chữ-link primary, không nền — hành động nhẹ.
  text,

  /// Nền/chữ đỏ — hành động phá huỷ (Xoá / Reset).
  danger,
}

/// Nút dùng chung cho toàn app.
///
/// - Hình pill, đúng token màu/typography.
/// - Có micro-interaction Apple: nhấn → `scale(0.95)` (mọi variant).
/// - [loading] = true → hiện spinner + tự khoá nút.
/// - [expanded] = true → giãn full chiều ngang (mặc định).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool v) {
    if (!_enabled) return;
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildVariant(context);

    final button = GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: child,
      ),
    );

    return widget.expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildVariant(BuildContext context) {
    final content = _content(context);
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return FilledButton(onPressed: _enabled ? widget.onPressed : null, child: content);
      case AppButtonVariant.secondary:
        return OutlinedButton(onPressed: _enabled ? widget.onPressed : null, child: content);
      case AppButtonVariant.text:
        return TextButton(onPressed: _enabled ? widget.onPressed : null, child: content);
      case AppButtonVariant.danger:
        return FilledButton(
          onPressed: _enabled ? widget.onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.pill)),
          ),
          child: content,
        );
    }
  }

  Widget _content(BuildContext context) {
    if (widget.loading) {
      final color = widget.variant == AppButtonVariant.primary ||
              widget.variant == AppButtonVariant.danger
          ? Colors.white
          : AppColors.primary;
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
      );
    }
    if (widget.icon == null) return Text(widget.label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, size: 20),
        const SizedBox(width: Sp.xs),
        Text(widget.label),
      ],
    );
  }
}
