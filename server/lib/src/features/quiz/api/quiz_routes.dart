import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../core/auth/app_user.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/http/json_response.dart';
import '../dto/save_quiz_request.dart';
import '../services/quiz_service.dart';

class QuizRoutes {
  QuizRoutes(this._service);

  final QuizService _service;

  Router get router {
    return Router()
      ..get('/', _list)
      ..get('/<id>', _detail)
      ..post('/', _create)
      ..put('/<id>', _update)
      ..delete('/<id>', _delete);
  }

  Response _list(Request request) {
    final quizzes = _service.list(
      request.currentUser,
      status: request.url.queryParameters['status'],
    );
    return jsonOk(quizzes.map((quiz) => quiz.toJson()).toList());
  }

  Response _detail(Request request, String id) {
    final quiz = _service.detail(request.currentUser, _parseId(id));
    return jsonOk(quiz.toJson());
  }

  Future<Response> _create(Request request) async {
    final input = SaveQuizRequest.fromJson(await _readJson(request));
    final quiz = _service.create(request.currentUser, input);
    return jsonOk(quiz.toJson(), statusCode: 201);
  }

  Future<Response> _update(Request request, String id) async {
    final input = SaveQuizRequest.fromJson(await _readJson(request));
    final quiz = _service.update(request.currentUser, _parseId(id), input);
    return jsonOk(quiz.toJson());
  }

  Response _delete(Request request, String id) {
    _service.delete(request.currentUser, _parseId(id));
    return Response(204);
  }

  int _parseId(String raw) {
    return int.tryParse(raw) ??
        (throw ApiException.badRequest('Quiz ID không hợp lệ.'));
  }

  Future<Map<String, Object?>> _readJson(Request request) async {
    final decoded = jsonDecode(await request.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw ApiException.badRequest('Request body phải là JSON object.');
    }
    return decoded.cast<String, Object?>();
  }
}
