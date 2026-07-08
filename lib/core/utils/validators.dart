import '../constants/app_strings.dart';

/// Hàm kiểm tra input dùng chung cho `TextFormField.validator`.
///
/// Trả `null` nếu hợp lệ, hoặc chuỗi lỗi (tiếng Việt) nếu sai —
/// đúng giao kèo của Flutter Form. Gắn với MSG-code trong SRS khi cần.
class Validators {
  Validators._();

  static final _emailRegExp = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// Không được để trống.
  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? AppStrings.requiredField;
    }
    return null;
  }

  /// Email hợp lệ (và không trống).
  static String? email(String? value) {
    final empty = required(value);
    if (empty != null) return empty;
    if (!_emailRegExp.hasMatch(value!.trim())) return AppStrings.invalidEmail;
    return null;
  }

  /// Mật khẩu: không trống + tối thiểu [min] ký tự (mặc định 6).
  static String? password(String? value, {int min = 6}) {
    final empty = required(value);
    if (empty != null) return empty;
    if (value!.length < min) return AppStrings.passwordTooShort;
    return null;
  }

  /// Xác nhận mật khẩu khớp với [original].
  static String? confirmPassword(String? value, String? original) {
    final empty = required(value);
    if (empty != null) return empty;
    if (value != original) return AppStrings.passwordMismatch;
    return null;
  }

  /// Độ dài tối đa (vd tiêu đề bộ thẻ — SRS 2.1.16 step 6).
  static String? maxLength(String? value, int max, {String? message}) {
    if (value != null && value.length > max) {
      return message ?? 'Tối đa $max ký tự';
    }
    return null;
  }

  /// Ghép nhiều validator: trả lỗi đầu tiên gặp phải.
  static String? Function(String?) compose(List<String? Function(String?)> rules) {
    return (value) {
      for (final rule in rules) {
        final res = rule(value);
        if (res != null) return res;
      }
      return null;
    };
  }
}
