import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import 'create_quiz_from_sets_page.dart';
import 'class_quiz_results_page.dart';
import 'publish_quiz_page.dart';
import 'student_quiz_page.dart';

class QuizPlaceholderPage extends ConsumerWidget {
  const QuizPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref
        .watch(authControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (user == null) {
      return const Scaffold(
        appBar: _QuizAppBar(),
        body: Center(child: Text('Đăng nhập để xem bài kiểm tra.')),
      );
    }
    return user.role == 'teacher' || user.role == 'admin'
        ? _TeacherQuizPage(user: user)
        : StudentQuizPage(user: user);
  }
}

class _QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _QuizAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Bài kiểm tra'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TeacherQuizPage extends ConsumerWidget {
  const _TeacherQuizPage({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(setsProvider(''));
    final quizzes = ref.watch(teacherQuizzesProvider(user.id));
    final archivedQuizzes = ref.watch(archivedTeacherQuizzesProvider(user.id));

    return Scaffold(
      appBar: const _QuizAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Quản lý bài kiểm tra',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Giáo viên tạo bài kiểm tra từ bộ thẻ. Khi xuất bản phải chọn một lớp cụ thể.',
          ),
          const SizedBox(height: 20),
          Text(
            'Tạo bài kiểm tra',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          sets.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('$error'),
            data: (items) => FilledButton.icon(
              onPressed: items.isEmpty
                  ? null
                  : () async {
                      final created =
                          await Navigator.of(
                            context,
                            rootNavigator: true,
                          ).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) => CreateQuizFromSetsPage(
                                teacher: user,
                                sets: items,
                              ),
                            ),
                          );
                      if (created != true || !context.mounted) return;
                      ref.invalidate(teacherQuizzesProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tạo bài kiểm tra thành công. Bài kiểm tra đã được lưu ở trạng thái Nháp.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_task),
              label: const Text('Tạo bài kiểm tra từ bộ thẻ'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ArchivedQuizzesPage(teacher: user),
              ),
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(
              archivedQuizzes.maybeWhen(
                data: (items) => 'Mở kho lưu trữ (${items.length})',
                orElse: () => 'Mở kho lưu trữ',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bài kiểm tra đã tạo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          quizzes.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('$error'),
            data: (items) {
              if (items.isEmpty) {
                return const Card(
                  child: ListTile(title: Text('Chưa tạo bài kiểm tra nào')),
                );
              }
              return Column(
                children: items
                    .map(
                      (quiz) => Card(
                        child: ListTile(
                          title: Text(quiz.title),
                          subtitle: Text(_quizSubtitle(quiz)),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Cập nhật',
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final updated = await Navigator.of(context)
                                      .push<bool>(
                                        MaterialPageRoute<bool>(
                                          builder: (_) => _TeacherQuizEditPage(
                                            quizId: quiz.id,
                                          ),
                                        ),
                                      );
                                  if (updated != true || !context.mounted) {
                                    return;
                                  }
                                  ref.invalidate(teacherQuizzesProvider);
                                  ref.invalidate(teacherQuizProvider(quiz.id));
                                  ref.invalidate(
                                    teacherQuizQuestionsProvider(quiz.id),
                                  );
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => _TeacherQuizDetailPage(
                                        quizId: quiz.id,
                                      ),
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cập nhật bài kiểm tra thành công',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Xóa / lưu trữ',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _confirmArchive(context, ref, quiz),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  _TeacherQuizDetailPage(quizId: quiz.id),
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

  String _quizSubtitle(TeacherQuiz quiz) {
    return quiz.status == 'published'
        ? '${quiz.questionCount} câu - đã xuất bản'
        : '${quiz.questionCount} câu - nháp, chưa giao lớp';
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    TeacherQuiz quiz,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bài kiểm tra?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bài kiểm tra sẽ được chuyển vào kho lưu trữ, không bị xóa vĩnh viễn.',
            ),
            const SizedBox(height: 12),
            Text(quiz.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Số câu hỏi: ${quiz.questionCount}'),
            Text('Thời gian: ${quiz.timeLimitMinutes} phút'),
            Text(
              'Trạng thái: ${quiz.status == 'published' ? 'Đã xuất bản' : 'Nháp'}',
            ),
            if (quiz.status == 'published') ...[
              const SizedBox(height: 8),
              const Text(
                'Bài kiểm tra sẽ được gỡ khỏi tất cả lớp đã nhận.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final archived = await ref
        .read(repositoryProvider)
        .archiveQuiz(quizId: quiz.id, teacherId: user.id);
    if (!context.mounted) return;
    if (!archived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu trữ bài kiểm tra.')),
      );
      return;
    }
    ref.invalidate(teacherQuizzesProvider);
    ref.invalidate(archivedTeacherQuizzesProvider);
    ref.invalidate(assignedQuizClassroomsProvider(quiz.id));
    ref.invalidate(availableQuizClassroomsProvider);
    ref.invalidate(assignedStudentQuizzesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chuyển bài kiểm tra vào kho lưu trữ.')),
    );
  }
}

class _ArchivedQuizzesPage extends ConsumerWidget {
  const _ArchivedQuizzesPage({required this.teacher});

  final AppUser teacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedQuizzes = ref.watch(
      archivedTeacherQuizzesProvider(teacher.id),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Kho lưu trữ bài kiểm tra')),
      body: archivedQuizzes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Chưa có bài kiểm tra nào được lưu trữ.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(quiz.title),
                  subtitle: Text(
                    '${quiz.questionCount} câu • Đã gỡ khỏi danh sách và lớp học',
                  ),
                  trailing: IconButton(
                    tooltip: 'Khôi phục',
                    icon: const Icon(Icons.restore),
                    onPressed: () => _restore(context, ref, quiz),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    TeacherQuiz quiz,
  ) async {
    final restored = await ref
        .read(repositoryProvider)
        .restoreQuiz(quizId: quiz.id, teacherId: teacher.id);
    if (!context.mounted) return;
    if (!restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể khôi phục bài kiểm tra.')),
      );
      return;
    }
    ref.invalidate(archivedTeacherQuizzesProvider);
    ref.invalidate(teacherQuizzesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã khôi phục bài kiểm tra về trạng thái Nháp.'),
      ),
    );
  }
}

class _TeacherQuizDetailPage extends ConsumerWidget {
  const _TeacherQuizDetailPage({required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizValue = ref.watch(teacherQuizProvider(quizId));
    final questionsValue = ref.watch(teacherQuizQuestionsProvider(quizId));
    final assignedClassesValue = ref.watch(
      assignedQuizClassroomsProvider(quizId),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài kiểm tra')),
      body: quizValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (quiz) {
          if (quiz == null) {
            return const Center(child: Text('Không tìm thấy bài kiểm tra.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                quiz.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Trạng thái'),
                      trailing: Text(
                        quiz.status == 'published' ? 'Đã xuất bản' : 'Nháp',
                      ),
                    ),
                    ListTile(
                      title: const Text('Giới hạn thời gian'),
                      trailing: Text('${quiz.timeLimitMinutes} phút'),
                    ),
                    ListTile(
                      title: const Text('Thứ tự câu hỏi'),
                      trailing: Text(_orderLabel(quiz.questionOrder)),
                    ),
                    ListTile(
                      title: const Text('Số câu hỏi'),
                      trailing: Text('${quiz.questionCount}'),
                    ),
                    ListTile(
                      title: const Text('Các lớp đã nhận bài'),
                      subtitle: assignedClassesValue.when(
                        loading: () => const Text('Đang tải...'),
                        error: (error, stackTrace) => Text('$error'),
                        data: (assignedClasses) => Text(
                          assignedClasses.isEmpty
                              ? 'Chưa xuất bản cho lớp nào'
                              : assignedClasses
                                    .map((classroom) => classroom.name)
                                    .join(', '),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuizClassroomsResultsPage(quiz: quiz),
                      ),
                    ),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Xem kết quả lớp'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => _TeacherQuizEditPage(quizId: quiz.id),
                    ),
                  );
                  if (updated != true || !context.mounted) return;
                  ref.invalidate(teacherQuizProvider(quiz.id));
                  ref.invalidate(teacherQuizQuestionsProvider(quiz.id));
                  ref.invalidate(teacherQuizzesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật bài kiểm tra thành công'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Cập nhật'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final published =
                      await Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => PublishQuizPage(
                            quiz: quiz,
                            teacherId: quiz.teacherId,
                          ),
                        ),
                      );
                  if (published != true || !context.mounted) return;
                  ref.invalidate(teacherQuizProvider(quiz.id));
                  ref.invalidate(teacherQuizzesProvider);
                  ref.invalidate(assignedQuizClassroomsProvider(quiz.id));
                  ref.invalidate(availableQuizClassroomsProvider);
                  ref.invalidate(assignedStudentQuizzesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xuất bản bài kiểm tra thành công.'),
                    ),
                  );
                },
                icon: const Icon(Icons.publish),
                label: Text(
                  quiz.status == 'published'
                      ? 'Xuất bản thêm cho lớp'
                      : 'Xuất bản cho lớp',
                ),
              ),
              const SizedBox(height: 20),
              Text('Câu hỏi', style: Theme.of(context).textTheme.titleLarge),
              questionsValue.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('$error'),
                data: (questions) => Column(
                  children: questions
                      .map(
                        (item) => ListTile(
                          title: Text(item.prompt),
                          subtitle: Text(item.correctAnswer),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherQuizEditPage extends ConsumerStatefulWidget {
  const _TeacherQuizEditPage({required this.quizId});

  final String quizId;

  @override
  ConsumerState<_TeacherQuizEditPage> createState() =>
      _TeacherQuizEditPageState();
}

class _TeacherQuizEditPageState extends ConsumerState<_TeacherQuizEditPage> {
  final _title = TextEditingController();
  final _timeLimit = TextEditingController();
  final _questionCount = TextEditingController();
  bool _initialized = false;
  bool _questionsInitialized = false;
  bool _isSaving = false;
  String _questionOrder = 'sequential';
  String? _questionCountError;
  List<TeacherQuizQuestion> _draftQuestions = const [];

  @override
  void dispose() {
    _title.dispose();
    _timeLimit.dispose();
    _questionCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizValue = ref.watch(teacherQuizProvider(widget.quizId));
    final questionsValue = ref.watch(
      teacherQuizQuestionsProvider(widget.quizId),
    );
    final sourceCardCountValue = ref.watch(
      teacherQuizSourceCardCountProvider(widget.quizId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cập nhật bài kiểm tra')),
      body: quizValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (quiz) {
          if (quiz == null) {
            return const Center(child: Text('Không tìm thấy bài kiểm tra.'));
          }
          _initForm(quiz);
          questionsValue.maybeWhen(data: _initQuestions, orElse: () {});
          final currentQuestionCount = _questionsInitialized
              ? _draftQuestions.length
              : questionsValue.maybeWhen(
                  data: (questions) => questions.length,
                  orElse: () => quiz.questionCount,
                );
          final sourceCardCount = sourceCardCountValue.maybeWhen<int?>(
            data: (count) => count,
            orElse: () => null,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề bài kiểm tra',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeLimit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giới hạn thời gian (phút)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _questionCount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số câu hỏi',
                  errorText: _questionCountError,
                  helperText: _questionCountError == null
                      ? _questionCountHint(
                          currentQuestionCount,
                          sourceCardCount,
                        )
                      : null,
                ),
                onChanged: (value) {
                  final requested = int.tryParse(value.trim());
                  setState(() {
                    _questionCountError =
                        sourceCardCount != null &&
                            requested != null &&
                            requested > sourceCardCount
                        ? 'Chỉ có tối đa $sourceCardCount câu từ bộ thẻ nguồn'
                        : null;
                  });
                },
              ),
              if (sourceCardCountValue.hasError)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Không đọc được số thẻ nguồn.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _questionOrder,
                decoration: const InputDecoration(labelText: 'Thứ tự câu hỏi'),
                items: const [
                  DropdownMenuItem(value: 'sequential', child: Text('Tuần tự')),
                  DropdownMenuItem(value: 'random', child: Text('Ngẫu nhiên')),
                ],
                onChanged: (value) => setState(() {
                  _questionOrder = value ?? 'sequential';
                  _questionCountError = null;
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Câu hỏi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Thêm câu hỏi từ bộ thẻ',
                    onPressed: !_questionsInitialized
                        ? null
                        : () async {
                            final generated = await ref
                                .read(repositoryProvider)
                                .generateAdditionalQuizQuestions(
                                  quizId: widget.quizId,
                                  existingQuestions: _draftQuestions,
                                  count: 1,
                                );
                            if (!context.mounted) return;
                            if (generated.isEmpty) {
                              _showMessage(
                                'Không còn câu hỏi mới trong các bộ thẻ nguồn.',
                              );
                              return;
                            }
                            setState(() {
                              _draftQuestions = [
                                ..._draftQuestions,
                                ...generated,
                              ];
                              _questionCount.text = '${_draftQuestions.length}';
                              _questionCountError = null;
                            });
                          },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              questionsValue.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('$error'),
                data: (questions) {
                  _initQuestions(questions);
                  if (_draftQuestions.isEmpty) {
                    return const Card(
                      child: ListTile(title: Text('Chưa có câu hỏi')),
                    );
                  }
                  return Column(
                    children: _draftQuestions
                        .map(
                          (question) => Card(
                            child: ListTile(
                              title: Text(question.prompt),
                              subtitle: Text(question.correctAnswer),
                              trailing: IconButton(
                                tooltip: 'Xóa câu hỏi',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    _draftQuestions = _draftQuestions
                                        .where((item) => item.id != question.id)
                                        .toList();
                                    _questionCount.text =
                                        '${_draftQuestions.length}';
                                    _questionCountError = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _initForm(TeacherQuiz quiz) {
    if (_initialized) return;
    _initialized = true;
    _title.text = quiz.title;
    _timeLimit.text = '${quiz.timeLimitMinutes}';
    _questionCount.text = '${quiz.questionCount}';
    _questionOrder = quiz.questionOrder;
  }

  void _initQuestions(List<TeacherQuizQuestion> questions) {
    if (_questionsInitialized) return;
    _questionsInitialized = true;
    _draftQuestions = List<TeacherQuizQuestion>.of(questions);
  }

  String _questionCountHint(int currentCount, int? sourceCardCount) {
    if (sourceCardCount == null) return 'Đang kiểm tra bộ thẻ nguồn...';
    final requested = int.tryParse(_questionCount.text.trim());
    if (requested == null || requested == currentCount) {
      return 'Hiện có $currentCount câu • Tối đa $sourceCardCount câu';
    }
    if (requested > currentCount && requested <= sourceCardCount) {
      return 'Khi lưu, hệ thống sẽ tự động tạo thêm '
          '${requested - currentCount} câu.';
    }
    if (requested < currentCount && _questionOrder == 'random') {
      return 'Khi lưu, hệ thống sẽ tự động xóa ngẫu nhiên '
          '${currentCount - requested} câu.';
    }
    if (requested < currentCount) {
      return 'Hãy chọn xóa ${currentCount - requested} câu cụ thể '
          'trong danh sách bên dưới.';
    }
    return 'Tối đa $sourceCardCount câu từ các bộ thẻ nguồn';
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final timeLimit = int.tryParse(_timeLimit.text.trim());
    final questionCount = int.tryParse(_questionCount.text.trim());
    if (title.isEmpty) {
      _showMessage('Tiêu đề không được để trống');
      return;
    }
    if (timeLimit == null || timeLimit < 1 || timeLimit > 180) {
      _showMessage('Giới hạn thời gian phải từ 1 đến 180 phút');
      return;
    }
    final sourceCardCount = await ref
        .read(repositoryProvider)
        .quizSourceCardCount(widget.quizId);
    if (!mounted) return;
    if (questionCount == null ||
        questionCount < 1 ||
        questionCount > sourceCardCount) {
      setState(() {
        _questionCountError = 'Số câu hỏi phải từ 1 đến $sourceCardCount';
      });
      return;
    }
    if (questionCount < _draftQuestions.length &&
        _questionOrder == 'sequential') {
      setState(() {
        _questionCountError =
            'Hãy chọn xóa ${_draftQuestions.length - questionCount} câu cụ thể '
            'bằng nút thùng rác trước khi lưu.';
      });
      return;
    }
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(repositoryProvider);
      var questionsToSave = List<TeacherQuizQuestion>.of(_draftQuestions);
      if (questionCount > questionsToSave.length) {
        final missingCount = questionCount - questionsToSave.length;
        final generated = await repository.generateAdditionalQuizQuestions(
          quizId: widget.quizId,
          existingQuestions: questionsToSave,
          count: missingCount,
        );
        if (generated.length != missingCount) {
          throw StateError('Không đủ thẻ nguồn để tạo $questionCount câu hỏi.');
        }
        questionsToSave = [...questionsToSave, ...generated];
      } else if (questionCount < questionsToSave.length) {
        final shuffled = List<TeacherQuizQuestion>.of(questionsToSave)
          ..shuffle();
        final idsToRemove = shuffled
            .take(questionsToSave.length - questionCount)
            .map((question) => question.id)
            .toSet();
        questionsToSave = questionsToSave
            .where((question) => !idsToRemove.contains(question.id))
            .toList();
      }
      await repository.updateQuiz(
        quizId: widget.quizId,
        title: title,
        timeLimitMinutes: timeLimit,
        questionOrder: _questionOrder,
        questions: questionsToSave,
      );
      ref.invalidate(teacherQuizProvider(widget.quizId));
      ref.invalidate(teacherQuizQuestionsProvider(widget.quizId));
      ref.invalidate(teacherQuizzesProvider);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Không thể cập nhật bài kiểm tra: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Kept temporarily for compatibility with the previous student quiz flow.
// ignore: unused_element
class _StudentQuizPage extends ConsumerWidget {
  const _StudentQuizPage({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const _QuizAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bài kiểm tra của học sinh',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Vai trò học sinh: làm bài kiểm tra đã được giao.'),
          const SizedBox(height: 12),
          ref
              .watch(assignedStudentQuizzesProvider(user.id))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('$error'),
                data: (quizzes) {
                  if (quizzes.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.assignment_outlined),
                        title: Text('Chưa có bài kiểm tra nào được giao'),
                      ),
                    );
                  }
                  return Column(
                    children: quizzes
                        .map(
                          (quiz) => Card(
                            child: ListTile(
                              title: Text(quiz.title),
                              subtitle: Text(
                                '${quiz.questionCount} câu • '
                                '${quiz.timeLimitMinutes} phút',
                              ),
                              trailing: const Icon(Icons.play_arrow),
                              onTap: () async {
                                final storedQuestions = await ref
                                    .read(repositoryProvider)
                                    .quizQuestions(quiz.id);
                                final questions = storedQuestions
                                    .map(
                                      (question) => QuizQuestion(
                                        prompt: question.prompt,
                                        options: question.options.isEmpty
                                            ? [question.correctAnswer]
                                            : question.options,
                                        correctIndex: question.options.isEmpty
                                            ? 0
                                            : question.correctIndex,
                                      ),
                                    )
                                    .toList();
                                if (quiz.questionOrder == 'random') {
                                  questions.shuffle();
                                }
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => _QuizRunPage(
                                      title: quiz.title,
                                      setId: quiz.setId,
                                      questions: questions,
                                      userId: user.id,
                                    ),
                                  ),
                                );
                                ref.invalidate(quizHistoryProvider);
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
            'Kết quả đã làm',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          ref
              .watch(quizHistoryProvider(user.id))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('$error'),
                data: (rows) => Column(
                  children: rows
                      .map(
                        (row) => ListTile(
                          title: Text(row['title'] as String),
                          trailing: Text('${row['score']}/${row['total']}'),
                        ),
                      )
                      .toList(),
                ),
              ),
        ],
      ),
    );
  }
}

class _QuizRunPage extends ConsumerStatefulWidget {
  const _QuizRunPage({
    required this.title,
    required this.setId,
    required this.questions,
    required this.userId,
  });

  final String title;
  final String setId;
  final List<QuizQuestion> questions;
  final String userId;

  @override
  ConsumerState<_QuizRunPage> createState() => _QuizRunPageState();
}

class _QuizRunPageState extends ConsumerState<_QuizRunPage> {
  int _index = 0;
  int _score = 0;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Bộ thẻ cần tối thiểu 4 thẻ để sinh quiz.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _done ? _result(context) : _question(context),
      ),
    );
  }

  Widget _question(BuildContext context) {
    final q = widget.questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: (_index + 1) / widget.questions.length),
        const SizedBox(height: 16),
        Text(
          'Câu ${_index + 1}/${widget.questions.length}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(q.prompt, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () => _answer(i),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(q.options[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Kết quả bài kiểm tra',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text('Điểm: $_score/${widget.questions.length}'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hoàn thành'),
        ),
      ],
    );
  }

  Future<void> _answer(int selected) async {
    if (selected == widget.questions[_index].correctIndex) _score++;
    if (_index == widget.questions.length - 1) {
      await ref
          .read(repositoryProvider)
          .saveQuizAttempt(
            widget.userId,
            widget.setId,
            _score,
            widget.questions.length,
          );
      setState(() => _done = true);
    } else {
      setState(() => _index++);
    }
  }
}

String _orderLabel(String value) {
  return value == 'random' ? 'Ngẫu nhiên' : 'Tuần tự';
}
