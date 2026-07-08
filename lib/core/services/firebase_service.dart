/// Kết nối Firebase (Auth / Firestore).
///
/// ⚠️ HIỆN LÀ STUB — chưa bật package Firebase để giữ project chạy được ngay.
/// Đề bài cho phép dùng Firebase làm backend đăng nhập + lưu dữ liệu realtime;
/// khi cần bật:
///
/// 1. `flutter pub add firebase_core firebase_auth cloud_firestore`
/// 2. `flutterfire configure` (sinh `firebase_options.dart`).
/// 3. Bỏ comment phần init bên dưới và gọi `await FirebaseService.instance.init()`
///    trong `main.dart` trước `runApp`.
///
/// Tách qua service này để tầng repository không phụ thuộc trực tiếp Firebase,
/// dễ thay bằng REST API (xem [ApiService]) mà không sửa UI.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Khởi tạo Firebase. Hiện chỉ đánh dấu cờ; nối thật khi bật package.
  Future<void> init() async {
    if (_initialized) return;
    // TODO(firebase): await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    _initialized = true;
  }
}
