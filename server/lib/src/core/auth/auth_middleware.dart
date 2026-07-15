import 'package:shelf/shelf.dart';

import '../../features/users/user_repository.dart';
import '../http/json_response.dart';
import 'app_user.dart';
import 'firebase_identity.dart';

Middleware authenticationMiddleware({
  required IdentityTokenVerifier tokenVerifier,
  required UserRepository users,
}) {
  return (innerHandler) {
    return (request) async {
      final header = request.headers['authorization'];
      if (header == null || !header.startsWith('Bearer ')) {
        return jsonError(
          statusCode: 401,
          code: 'missing_token',
          message: 'Thiếu Firebase ID token.',
        );
      }

      try {
        final token = header.substring('Bearer '.length).trim();
        final identity = await tokenVerifier.verify(token);
        final user = users.findOrCreate(identity);
        if (user.status != 'active') {
          return jsonError(
            statusCode: 403,
            code: 'account_inactive',
            message: 'Tài khoản đã bị khóa hoặc vô hiệu hóa.',
          );
        }

        return innerHandler(
          request.change(context: {authenticatedUserContextKey: user}),
        );
      } catch (_) {
        return jsonError(
          statusCode: 401,
          code: 'invalid_token',
          message: 'Firebase ID token không hợp lệ hoặc đã hết hạn.',
        );
      }
    };
  };
}
