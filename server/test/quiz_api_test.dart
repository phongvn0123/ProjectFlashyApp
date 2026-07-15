import 'dart:convert';
import 'dart:io';

import 'package:flashly_server/flashly_server.dart';
import 'package:flashly_server/src/core/auth/firebase_token_verifier.dart';
import 'package:flashly_server/src/core/database/server_database.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late ServerDatabase database;
  late Handler handler;

  setUp(() {
    database = ServerDatabase.inMemory(
      schema: File('migrations/001_initial_schema.sql').readAsStringSync(),
    );
    handler = buildFlashlyHandler(
      database: database,
      tokenVerifier: const DevelopmentTokenVerifier(),
    );
  });

  tearDown(() => database.close());

  test('Student gọi GET /api/quizzes và chỉ nhận quiz published', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/api/quizzes/'),
        headers: {'authorization': 'Bearer dev-student'},
      ),
    );
    final json =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    final data = json['data'] as List;

    expect(response.statusCode, 200);
    expect(data, isNotEmpty);
    expect(data.every((item) => item['status'] == 'published'), isTrue);
  });

  test('Teacher tạo quiz qua POST /api/quizzes', () async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/quizzes/'),
        headers: {
          'authorization': 'Bearer dev-teacher',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'title': 'Quiz API mới',
          'questionCount': 4,
          'status': 'draft',
        }),
      ),
    );

    expect(response.statusCode, 201);
  });
}
