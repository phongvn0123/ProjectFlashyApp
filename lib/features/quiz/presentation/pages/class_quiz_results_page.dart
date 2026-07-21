import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';

class QuizClassroomsResultsPage extends ConsumerWidget {
  const QuizClassroomsResultsPage({required this.quiz, super.key});

  final TeacherQuiz quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(assignedQuizClassroomsProvider(quiz.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả bài kiểm tra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            quiz.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Chọn lớp học để xem kết quả và xếp hạng.'),
          const SizedBox(height: 20),
          Text(
            'Lớp đã nhận bài',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          classrooms.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('$error'),
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Bài kiểm tra chưa được giao cho lớp nào.'),
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (classroom) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.groups_outlined),
                          ),
                          title: Text(classroom.name),
                          subtitle: Text('Mã lớp: ${classroom.joinCode}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ClassQuizResultsPage(
                                quiz: quiz,
                                classroom: classroom,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ClassQuizResultsPage extends ConsumerWidget {
  const ClassQuizResultsPage({
    required this.quiz,
    required this.classroom,
    super.key,
  });

  final TeacherQuiz quiz;
  final Classroom classroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (quizId: quiz.id, classroomId: classroom.id);
    final performance = ref.watch(classQuizPerformanceProvider(request));
    return Scaffold(
      appBar: AppBar(title: Text('Kết quả: ${quiz.title}')),
      body: performance.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(classQuizPerformanceProvider(request));
            await ref.read(classQuizPerformanceProvider(request).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B63B8), Color(0xFF064788)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_scoreText(data.averageScore)}/10',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Điểm trung bình của lớp',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.65,
                children: [
                  _MetricCard(
                    label: 'Được giao',
                    value: '${data.assignedCount}',
                    icon: Icons.groups_outlined,
                  ),
                  _MetricCard(
                    label: 'Đã hoàn thành',
                    value: '${data.completedCount}',
                    icon: Icons.check_circle_outline,
                  ),
                  _MetricCard(
                    label: 'Chưa bắt đầu',
                    value: '${data.notStartedCount}',
                    icon: Icons.pending_outlined,
                  ),
                  _MetricCard(
                    label: 'Cao nhất',
                    value: '${_scoreText(data.highestScore)}/10',
                    icon: Icons.trending_up,
                  ),
                  _MetricCard(
                    label: 'Thấp nhất',
                    value: '${_scoreText(data.lowestScore)}/10',
                    icon: Icons.trending_down,
                  ),
                  _MetricCard(
                    label: 'Trung bình',
                    value: '${_scoreText(data.averageScore)}/10',
                    icon: Icons.analytics_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Danh sách học sinh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (data.students.isEmpty)
                const Card(
                  child: ListTile(title: Text('Lớp chưa có học sinh.')),
                )
              else
                ...data.students.indexed.map(
                  (entry) => _StudentResultTile(
                    rank: entry.$1 + 1,
                    result: entry.$2,
                    onTap: entry.$2.attemptId == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => StudentQuizResultDetailPage(
                                quiz: quiz,
                                classroom: classroom,
                                result: entry.$2,
                              ),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentResultTile extends StatelessWidget {
  const _StudentResultTile({
    required this.rank,
    required this.result,
    required this.onTap,
  });

  final int rank;
  final StudentQuizResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final score = result.scoreOutOfTen;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('$rank')),
        title: Text(result.studentName),
        subtitle: Text(
          'ID: ${result.studentId}\n'
          '${result.status == 'completed' ? 'Đã hoàn thành' : 'Chưa bắt đầu'}'
          '${result.submittedAt == null ? '' : ' • ${_dateTime(result.submittedAt!)}'}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              score == null ? '--' : score.toStringAsFixed(1),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class StudentQuizResultDetailPage extends ConsumerWidget {
  const StudentQuizResultDetailPage({
    required this.quiz,
    required this.classroom,
    required this.result,
    super.key,
  });

  final TeacherQuiz quiz;
  final Classroom classroom;
  final StudentQuizResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(
      quizAttemptAnswerReviewsProvider(result.attemptId!),
    );
    final correct = result.score ?? 0;
    final total = result.total ?? quiz.questionCount;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết kết quả')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            result.studentName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text('${classroom.name} • ${quiz.title}'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResultValue(
                    label: 'Điểm',
                    value: '${_scoreText(result.scoreOutOfTen)}/10',
                  ),
                  _ResultValue(label: 'Đúng', value: '$correct'),
                  _ResultValue(label: 'Sai', value: '${total - correct}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Câu trả lời', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          reviews.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('$error'),
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Lượt làm cũ chưa có dữ liệu đáp án chi tiết.'),
                  ),
                );
              }
              return Column(
                children: items.indexed
                    .map(
                      (entry) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    entry.$2.isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: entry.$2.isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Câu ${entry.$1 + 1}: ${entry.$2.prompt}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Học sinh chọn: '
                                '${entry.$2.selectedAnswer ?? 'Không trả lời'}',
                              ),
                              const SizedBox(height: 4),
                              Text('Đáp án đúng: ${entry.$2.correctAnswer}'),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
      ],
    );
  }
}

String _scoreText(double? score) => score?.toStringAsFixed(1) ?? '--';

String _dateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  final local = value.toLocal();
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
