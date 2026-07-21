import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';

class PublishQuizPage extends ConsumerStatefulWidget {
  const PublishQuizPage({
    required this.quiz,
    required this.teacherId,
    super.key,
  });

  final TeacherQuiz quiz;
  final String teacherId;

  @override
  ConsumerState<PublishQuizPage> createState() => _PublishQuizPageState();
}

class _PublishQuizPageState extends ConsumerState<PublishQuizPage> {
  final Set<String> _selectedClassIds = {};
  bool _isPublishing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final request = (teacherId: widget.teacherId, quizId: widget.quiz.id);
    final availableClasses = ref.watch(
      availableQuizClassroomsProvider(request),
    );
    final assignedClasses = ref.watch(
      assignedQuizClassroomsProvider(widget.quiz.id),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Xuất bản bài kiểm tra')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Thông tin bài kiểm tra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(title: Text(widget.quiz.title)),
                  ListTile(
                    title: const Text('Số câu hỏi'),
                    trailing: Text('${widget.quiz.questionCount}'),
                  ),
                  ListTile(
                    title: const Text('Thời gian'),
                    trailing: Text('${widget.quiz.timeLimitMinutes} phút'),
                  ),
                  ListTile(
                    title: const Text('Thứ tự câu hỏi'),
                    trailing: Text(_orderLabel(widget.quiz.questionOrder)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lớp đã nhận bài kiểm tra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            assignedClasses.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('$error'),
              data: (classrooms) {
                if (classrooms.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Chưa có lớp nào nhận bài kiểm tra này.'),
                    ),
                  );
                }
                return Column(
                  children: classrooms
                      .map(
                        (classroom) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: Text(classroom.name),
                            subtitle: Text(
                              'Mã tham gia: ${classroom.joinCode}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Lớp chưa nhận bài kiểm tra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            availableClasses.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('$error'),
              data: (classrooms) {
                if (classrooms.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Tất cả lớp đã nhận bài kiểm tra này.'),
                    ),
                  );
                }
                return Column(
                  children: classrooms
                      .map(
                        (classroom) => Card(
                          child: CheckboxListTile(
                            value: _selectedClassIds.contains(classroom.id),
                            title: Text(classroom.name),
                            subtitle: Text(
                              'Mã tham gia: ${classroom.joinCode}',
                            ),
                            onChanged: (selected) {
                              setState(() {
                                if (selected ?? false) {
                                  _selectedClassIds.add(classroom.id);
                                } else {
                                  _selectedClassIds.remove(classroom.id);
                                }
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Xác nhận lớp đã chọn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            availableClasses.maybeWhen(
              data: (classrooms) {
                final selected = classrooms
                    .where(
                      (classroom) => _selectedClassIds.contains(classroom.id),
                    )
                    .toList();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      selected.isEmpty
                          ? 'Chưa chọn lớp nào.'
                          : selected
                                .map((classroom) => classroom.name)
                                .join(', '),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isPublishing ? null : _confirmPublish,
              icon: _isPublishing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish),
              label: const Text('Xác nhận xuất bản'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPublish() async {
    final quiz = widget.quiz;
    if (quiz.title.trim().isEmpty ||
        quiz.questionCount < 1 ||
        quiz.timeLimitMinutes < 1 ||
        quiz.timeLimitMinutes > 180) {
      setState(() {
        _errorMessage = 'Thông tin bài kiểm tra không hợp lệ để xuất bản.';
      });
      return;
    }
    if (_selectedClassIds.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng chọn ít nhất một lớp học.';
      });
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await ref
          .read(repositoryProvider)
          .publishQuiz(
            quizId: quiz.id,
            teacherId: widget.teacherId,
            classroomIds: _selectedClassIds.toList(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _errorMessage = 'Không thể xuất bản: $error';
      });
    }
  }
}

String _orderLabel(String value) {
  return value == 'random' ? 'Ngẫu nhiên' : 'Tuần tự';
}
