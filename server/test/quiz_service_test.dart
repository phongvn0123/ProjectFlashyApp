import 'dart:io';

import 'package:flashly_server/src/core/auth/app_user.dart';
import 'package:flashly_server/src/core/database/server_database.dart';
import 'package:flashly_server/src/features/quiz/data/quiz_repository.dart';
import 'package:flashly_server/src/features/quiz/dto/save_quiz_request.dart';
import 'package:flashly_server/src/features/quiz/services/quiz_service.dart';
import 'package:test/test.dart';

void main() {
  late ServerDatabase database;
  late QuizService service;

  const teacher = AppUser(
    id: 1,
    firebaseUid: 'dev-teacher',
    email: 'teacher@flashly.local',
    role: 'teacher',
    status: 'active',
  );
  const student = AppUser(
    id: 2,
    firebaseUid: 'dev-student',
    email: 'student@flashly.local',
    role: 'student',
    status: 'active',
  );

  setUp(() {
    database = ServerDatabase.inMemory(
      schema: File('migrations/001_initial_schema.sql').readAsStringSync(),
    );
    service = QuizService(QuizRepository(database));
  });

  tearDown(() => database.close());

  test('Teacher tạo Quiz còn Student chỉ thấy Quiz đã công bố', () {
    final created = service.create(
      teacher,
      const SaveQuizRequest(
        title: 'Quiz mới',
        status: 'draft',
        questionCount: 3,
        shuffleOrder: false,
      ),
    );

    expect(created.teacherId, teacher.id);
    expect(service.list(teacher).any((quiz) => quiz.id == created.id), isTrue);
    expect(service.list(student).any((quiz) => quiz.id == created.id), isFalse);
  });
}
