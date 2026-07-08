/// Chuỗi text cố định dùng chung toàn app (tiếng Việt).
///
/// Gom về một chỗ để dễ sửa và sau này dễ đa ngôn ngữ (l10n).
/// Các thông báo validate gắn với MSG-code trong SRS ghi chú kèm.
class AppStrings {
  AppStrings._();

  static const appName = 'Flashly';
  static const appTagline = 'Học nhanh. Nhớ lâu.';

  // --- Hành động chung ---
  static const save = 'Lưu';
  static const cancel = 'Huỷ';
  static const delete = 'Xoá';
  static const confirm = 'Xác nhận';
  static const retry = 'Thử lại';
  static const create = 'Tạo';
  static const edit = 'Chỉnh sửa';
  static const search = 'Tìm kiếm';
  static const back = 'Quay lại';

  // --- Auth ---
  static const login = 'Đăng nhập';
  static const register = 'Đăng ký';
  static const logout = 'Đăng xuất';
  static const email = 'Email';
  static const username = 'Username';
  static const password = 'Mật khẩu';
  static const forgotPassword = 'Quên mật khẩu?';
  static const noAccount = 'Chưa có tài khoản?';
  static const haveAccount = 'Đã có tài khoản?';

  // --- Trạng thái rỗng / lỗi / loading ---
  static const loading = 'Đang tải…';
  static const genericError = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  static const networkError = 'Không tải được dữ liệu. Kiểm tra kết nối mạng.';
  static const emptyDefault = 'Chưa có dữ liệu.';

  // --- Thông báo validate (gắn MSG-code SRS) ---
  static const requiredField = 'Không được để trống';
  static const invalidEmail = 'Email không hợp lệ';
  static const passwordTooShort = 'Mật khẩu phải có ít nhất 6 ký tự';
  static const passwordMismatch = 'Mật khẩu nhập lại không khớp';
  static const wrongCredentials = 'Sai tài khoản hoặc mật khẩu';
}
