import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'src/core/auth/app_user.dart';
import 'src/core/auth/auth_middleware.dart';
import 'src/core/auth/firebase_identity.dart';
import 'src/core/database/server_database.dart';
import 'src/core/http/json_response.dart';
import 'src/features/quiz/api/quiz_routes.dart';
import 'src/features/quiz/data/quiz_repository.dart';
import 'src/features/quiz/services/quiz_service.dart';
import 'src/features/users/user_repository.dart';

Handler buildFlashlyHandler({
  required ServerDatabase database,
  required IdentityTokenVerifier tokenVerifier,
}) {
  final users = UserRepository(database);
  final quizService = QuizService(QuizRepository(database));

  final protectedRouter = Router()
    ..get(
      '/users/me',
      (Request request) => jsonOk(request.currentUser.toJson()),
    )
    ..mount('/quizzes/', QuizRoutes(quizService).router.call);

  final protectedHandler = const Pipeline()
      .addMiddleware(
        authenticationMiddleware(tokenVerifier: tokenVerifier, users: users),
      )
      .addHandler(protectedRouter.call);

  final root = Router()
    ..get('/health', (_) => jsonOk({'status': 'ok'}))
    ..mount('/api/', protectedHandler);

  return const Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(logRequests())
      .addMiddleware(errorMiddleware())
      .addHandler(root.call);
}
