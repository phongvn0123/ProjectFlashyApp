import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Điểm chạy đầu tiên của app.
///
/// - Bọc toàn app trong [ProviderScope] để Riverpod hoạt động ở mọi nơi.
/// - Khởi tạo dịch vụ nền (Firebase, local DB...) sẽ thêm ở đây sau khi
///   các package tương ứng được bật (xem `core/services/*`).
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(core): khi bật Firebase → `await FirebaseService.instance.init();`
  //             Local DB mở lazy ở lần dùng đầu (LocalDbService.instance.database).

  runApp(const ProviderScope(child: FlashlyApp()));
}
