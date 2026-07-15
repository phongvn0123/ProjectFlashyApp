class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {required this.code});

  final int statusCode;
  final String code;
  final String message;

  factory ApiException.badRequest(String message) =>
      ApiException(400, message, code: 'bad_request');

  factory ApiException.unauthorized([String message = 'Chưa đăng nhập.']) =>
      ApiException(401, message, code: 'unauthorized');

  factory ApiException.forbidden([
    String message = 'Không có quyền truy cập.',
  ]) => ApiException(403, message, code: 'forbidden');

  factory ApiException.notFound(String message) =>
      ApiException(404, message, code: 'not_found');
}
