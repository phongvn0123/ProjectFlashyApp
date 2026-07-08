import 'package:dio/dio.dart';

import '../constants/app_strings.dart';

/// Lỗi nghiệp vụ đã được "dịch" sang thông báo thân thiện cho người dùng.
///
/// Mọi tầng (service/repository) nên ném [AppException] thay vì để lộ
/// [DioException]/lỗi thô lên UI. [ErrorView] sẽ đọc [message] để hiển thị.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  /// Thông báo hiển thị cho người dùng (tiếng Việt).
  final String message;

  /// Mã lỗi tuỳ chọn — có thể map MSG-code của SRS hoặc HTTP status.
  final String? code;

  /// Nguyên nhân gốc (để log/debug, không hiện cho user).
  final Object? cause;

  /// Lỗi mạng/timeout/không kết nối.
  factory AppException.network([Object? cause]) =>
      AppException(AppStrings.networkError, code: 'network', cause: cause);

  /// Lỗi không xác định.
  factory AppException.unknown([Object? cause]) =>
      AppException(AppStrings.genericError, code: 'unknown', cause: cause);

  /// Dịch [DioException] → [AppException] với message theo HTTP status.
  factory AppException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return AppException.network(e);
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final serverMsg = _extractServerMessage(e.response?.data);
        return AppException(
          serverMsg ?? _messageForStatus(status),
          code: status?.toString(),
          cause: e,
        );
      case DioExceptionType.cancel:
        return const AppException('Yêu cầu đã bị huỷ.', code: 'cancel');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return AppException.network(e);
    }
  }

  static String _messageForStatus(int? status) {
    if (status == null) return AppStrings.genericError;
    return switch (status) {
      400 => 'Yêu cầu không hợp lệ.',
      401 => AppStrings.wrongCredentials,
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy dữ liệu.',
      409 => 'Dữ liệu bị xung đột.',
      >= 500 => 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
      _ => AppStrings.genericError,
    };
  }

  /// Cố gắng lấy field "message"/"error" nếu backend trả JSON.
  static String? _extractServerMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    return null;
  }

  @override
  String toString() => 'AppException($code): $message';
}
