import 'package:flashly_app/features/quiz/data/quiz_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QuizModel converts backend JSON to a Flutter model', () {
    final quiz = QuizModel.fromJson({
      'quizId': 1,
      'teacherId': 2,
      'title': 'Flutter Basic',
      'questionCount': 5,
      'shuffleOrder': true,
      'status': 'published',
      'createdAt': 1000,
      'updatedAt': 2000,
    });

    expect(quiz.id, 1);
    expect(quiz.title, 'Flutter Basic');
    expect(quiz.questionCount, 5);
    expect(quiz.shuffleOrder, isTrue);
    expect(quiz.isPublished, isTrue);
  });
}
