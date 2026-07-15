import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';

/// Điểm chạy đầu tiên của app.
///
/// - Bọc toàn app trong [ProviderScope] để Riverpod hoạt động ở mọi nơi.
/// - Khởi tạo dịch vụ nền (Firebase, local DB...) sẽ thêm ở đây sau khi
///   các package tương ứng được bật (xem `services/*`).
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // `sqflite` is used on Android/iOS. Windows and Linux do not provide the
  // mobile sqflite plugin, so point the same database API to its FFI backend.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // TODO(core): khi bật Firebase → `await FirebaseService.instance.init();`
  //             Local DB mở lazy ở lần dùng đầu (LocalDbService.instance.database).

  runApp(const ProviderScope(child: FlashlyApp()));
}
