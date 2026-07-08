import 'package:dio/dio.dart';

import '../utils/app_exception.dart';

/// Lớp gọi Backend API dùng chung (bọc `dio`).
///
/// - Cấu hình baseUrl/timeout một chỗ.
/// - Interceptor tự gắn Bearer token (nếu có) và log gọn khi debug.
/// - Mọi lỗi `DioException` được dịch sang [AppException] để UI hiển thị sạch.
///
/// Dùng ở tầng repository:
/// ```dart
/// final json = await api.get('/sets', query: {'filter': 'all'});
/// ```
class ApiService {
  ApiService({String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? defaultBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  /// TODO: đổi sang URL backend thật của nhóm (hoặc đọc từ biến môi trường).
  static const defaultBaseUrl = 'https://api.example.com';

  final Dio _dio;
  String? _authToken;

  /// Gắn/đổi token sau khi đăng nhập (gọi từ AuthRepository).
  void setAuthToken(String? token) => _authToken = token;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _request(() => _dio.post(path, data: body, queryParameters: query));

  Future<dynamic> put(String path, {Object? body}) =>
      _request(() => _dio.put(path, data: body));

  Future<dynamic> delete(String path, {Object? body}) =>
      _request(() => _dio.delete(path, data: body));

  /// Gọi request và chuẩn hoá lỗi.
  Future<dynamic> _request(Future<Response> Function() run) async {
    try {
      final res = await run();
      return res.data;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      throw AppException.unknown(e);
    }
  }
}
