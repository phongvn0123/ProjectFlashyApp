/// Vai trò người dùng trong hệ thống (SRS §1.1.1 Actors).
///
/// Dùng để bật/ẩn chức năng theo quyền (vd: chỉ Teacher mới tạo lớp,
/// chỉ Admin mới quản lý user). Lưu dưới dạng [String] khi giao tiếp
/// với API/Firebase qua [AppRole.fromString] / [AppRole.value].
enum AppRole {
  student('student'),
  teacher('teacher'),
  admin('admin');

  const AppRole(this.value);

  /// Giá trị chuỗi dùng cho API/DB.
  final String value;

  /// Parse an toàn từ chuỗi (mặc định [student] nếu không khớp).
  static AppRole fromString(String? raw) {
    return AppRole.values.firstWhere(
      (r) => r.value == raw?.trim().toLowerCase(),
      orElse: () => AppRole.student,
    );
  }

  bool get isStudent => this == AppRole.student;
  bool get isTeacher => this == AppRole.teacher;
  bool get isAdmin => this == AppRole.admin;

  /// Tên hiển thị tiếng Việt.
  String get label => switch (this) {
        AppRole.student => 'Học sinh',
        AppRole.teacher => 'Giáo viên',
        AppRole.admin => 'Quản trị viên',
      };
}
