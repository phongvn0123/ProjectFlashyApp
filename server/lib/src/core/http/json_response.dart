import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../errors/api_exception.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode({'data': data}),
    headers: _jsonHeaders,
  );
}

Response jsonError({
  required int statusCode,
  required String code,
  required String message,
}) {
  return Response(
    statusCode,
    body: jsonEncode({
      'error': {'code': code, 'message': message},
    }),
    headers: _jsonHeaders,
  );
}

Middleware errorMiddleware() {
  return (innerHandler) {
    return (request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (error) {
        return jsonError(
          statusCode: 400,
          code: 'invalid_json',
          message: error.message,
        );
      } catch (error, stackTrace) {
        if (error is ApiException) {
          return jsonError(
            statusCode: error.statusCode,
            code: error.code,
            message: error.message,
          );
        }
        // Không trả stack trace cho client.
        stderr.writeln(error);
        stderr.writeln(stackTrace);
        return jsonError(
          statusCode: 500,
          code: 'internal_error',
          message: 'Máy chủ gặp lỗi. Vui lòng thử lại.',
        );
      }
    };
  };
}

Middleware corsMiddleware() {
  const headers = {
    'access-control-allow-origin': '*',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
  };

  return (innerHandler) {
    return (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await innerHandler(request);
      return response.change(headers: {...response.headers, ...headers});
    };
  };
}
