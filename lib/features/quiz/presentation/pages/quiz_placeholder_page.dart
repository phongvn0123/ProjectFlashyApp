import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';

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
        : _StudentQuizPage(user: user);
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
    final classes = ref.watch(classroomProvider(user.id));

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
          Text('Tạo từ bộ thẻ', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          sets.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text('$error'),
            data: (items) => Column(
              children: items
                  .map(
                    (set) => Card(
                      child: ListTile(
                        title: Text(set.title),
                        subtitle: Text('${set.cardCount} thẻ'),
                        trailing: const Icon(Icons.add_task),
                        enabled: set.cardCount >= 4,
                        onTap: () => classes.when(
                          loading: () {},
                          error: (error, stackTrace) => ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$error'))),
                          data: (ownedClasses) => _showCreateQuizDialog(
                            context,
                            ref,
                            set,
                            ownedClasses,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
              return classes.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('$error'),
                data: (ownedClasses) => Column(
                  children: items
                      .map(
                        (quiz) => Card(
                          child: ListTile(
                            title: Text(quiz.title),
                            subtitle: Text(_quizSubtitle(quiz, ownedClasses)),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Cập nhật',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          _TeacherQuizEditPage(quizId: quiz.id),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _TeacherQuizDetailPage(
                                  quizId: quiz.id,
                                  classes: ownedClasses,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _quizSubtitle(TeacherQuiz quiz, List<Classroom> classes) {
    final className = _className(classes, quiz.assignedClassId);
    return quiz.status == 'published'
        ? '${quiz.questionCount} câu - đã giao: $className'
        : '${quiz.questionCount} câu - nháp, chưa giao lớp';
  }

  Future<void> _showCreateQuizDialog(
    BuildContext context,
    WidgetRef ref,
    FlashcardSet set,
    List<Classroom> classes,
  ) async {
    final title = TextEditingController(text: 'Kiểm tra: ${set.title}');
    var status = 'draft';
    String? selectedClassId = classes.isEmpty ? null : classes.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tạo bài kiểm tra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Nháp')),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Xuất bản cho lớp'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => status = value ?? 'draft'),
              ),
              if (status == 'published') ...[
                const SizedBox(height: 12),
                if (classes.isEmpty)
                  const Text('Bạn cần tạo lớp trước khi xuất bản bài kiểm tra.')
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Lớp nhận bài',
                    ),
                    items: classes
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedClassId = value),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                if (status == 'published' &&
                    (classes.isEmpty || selectedClassId == null)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tạo hoặc chọn lớp trước khi xuất bản'),
                    ),
                  );
                  return;
                }
                await ref
                    .read(repositoryProvider)
                    .createQuiz(
                      teacherId: user.id,
                      setId: set.id,
                      title: title.text,
                      questionCount: set.cardCount,
                      status: status,
                      assignedClassId: selectedClassId,
                    );
                ref.invalidate(teacherQuizzesProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
  }
}

class _TeacherQuizDetailPage extends ConsumerWidget {
  const _TeacherQuizDetailPage({required this.quizId, required this.classes});

  final String quizId;
  final List<Classroom> classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizValue = ref.watch(teacherQuizProvider(quizId));
    final questionsValue = ref.watch(teacherQuizQuestionsProvider(quizId));
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
                      title: const Text('Thứ tự câu trả lời'),
                      trailing: Text(_answerOrderLabel(quiz.answerOrder)),
                    ),
                    ListTile(
                      title: const Text('Số câu hỏi'),
                      trailing: Text('${quiz.questionCount}'),
                    ),
                    ListTile(
                      title: const Text('Lớp được giao'),
                      trailing: Text(_className(classes, quiz.assignedClassId)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _TeacherQuizEditPage(quizId: quiz.id),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Cập nhật'),
              ),
              if (quiz.status != 'published') ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showPublishDialog(context, ref, quiz),
                  icon: const Icon(Icons.publish),
                  label: const Text('Xuất bản cho lớp'),
                ),
              ],
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

  Future<void> _showPublishDialog(
    BuildContext context,
    WidgetRef ref,
    TeacherQuiz quiz,
  ) async {
    String? selectedClassId = classes.isEmpty ? null : classes.first.id;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Chọn lớp để xuất bản'),
          content: classes.isEmpty
              ? const Text('Bạn cần tạo lớp trước khi xuất bản bài kiểm tra.')
              : DropdownButtonFormField<String>(
                  initialValue: selectedClassId,
                  decoration: const InputDecoration(labelText: 'Lớp nhận bài'),
                  items: classes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedClassId = value),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: selectedClassId == null
                  ? null
                  : () async {
                      await ref
                          .read(repositoryProvider)
                          .publishQuiz(quiz.id, selectedClassId!);
                      ref.invalidate(teacherQuizzesProvider);
                      ref.invalidate(teacherQuizProvider(quiz.id));
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
              child: const Text('Xuất bản'),
            ),
          ],
        ),
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
  bool _initialized = false;
  String _questionOrder = 'sequential';
  String _answerOrder = 'fixed';

  @override
  void dispose() {
    _title.dispose();
    _timeLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizValue = ref.watch(teacherQuizProvider(widget.quizId));
    final questionsValue = ref.watch(
      teacherQuizQuestionsProvider(widget.quizId),
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
              DropdownButtonFormField<String>(
                initialValue: _questionOrder,
                decoration: const InputDecoration(labelText: 'Thứ tự câu hỏi'),
                items: const [
                  DropdownMenuItem(value: 'sequential', child: Text('Tuần tự')),
                  DropdownMenuItem(value: 'random', child: Text('Ngẫu nhiên')),
                ],
                onChanged: (value) =>
                    setState(() => _questionOrder = value ?? 'sequential'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _answerOrder,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự câu trả lời',
                ),
                items: const [
                  DropdownMenuItem(value: 'fixed', child: Text('Cố định')),
                  DropdownMenuItem(value: 'random', child: Text('Ngẫu nhiên')),
                ],
                onChanged: (value) =>
                    setState(() => _answerOrder = value ?? 'fixed'),
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
                    onPressed: () async {
                      await ref
                          .read(repositoryProvider)
                          .addQuestionFromSet(widget.quizId);
                      ref.invalidate(
                        teacherQuizQuestionsProvider(widget.quizId),
                      );
                      ref.invalidate(teacherQuizProvider(widget.quizId));
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              questionsValue.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('$error'),
                data: (questions) {
                  if (questions.isEmpty) {
                    return const Card(
                      child: ListTile(title: Text('Chưa có câu hỏi')),
                    );
                  }
                  return Column(
                    children: questions
                        .map(
                          (question) => Card(
                            child: ListTile(
                              title: Text(question.prompt),
                              subtitle: Text(question.correctAnswer),
                              trailing: IconButton(
                                tooltip: 'Xóa câu hỏi',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref
                                      .read(repositoryProvider)
                                      .deleteQuizQuestion(
                                        question.id,
                                        widget.quizId,
                                      );
                                  ref.invalidate(
                                    teacherQuizQuestionsProvider(widget.quizId),
                                  );
                                  ref.invalidate(
                                    teacherQuizProvider(widget.quizId),
                                  );
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
                onPressed: () => _save(
                  questionsValue.maybeWhen(
                    data: (questions) => questions,
                    orElse: () => const <TeacherQuizQuestion>[],
                  ),
                ),
                icon: const Icon(Icons.save),
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
    _questionOrder = quiz.questionOrder;
    _answerOrder = quiz.answerOrder;
  }

  Future<void> _save(List<TeacherQuizQuestion> questions) async {
    final title = _title.text.trim();
    final timeLimit = int.tryParse(_timeLimit.text.trim());
    if (title.isEmpty) {
      _showMessage('Tiêu đề không được để trống');
      return;
    }
    if (timeLimit == null || timeLimit < 1 || timeLimit > 180) {
      _showMessage('Giới hạn thời gian phải từ 1 đến 180 phút');
      return;
    }
    if (questions.isEmpty) {
      _showMessage('Bài kiểm tra phải có ít nhất 1 câu hỏi');
      return;
    }
    await ref
        .read(repositoryProvider)
        .updateQuiz(
          quizId: widget.quizId,
          title: title,
          timeLimitMinutes: timeLimit,
          questionOrder: _questionOrder,
          answerOrder: _answerOrder,
        );
    ref.invalidate(teacherQuizProvider(widget.quizId));
    ref.invalidate(teacherQuizzesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật bài kiểm tra thành công')),
    );
    Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

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
              .watch(setsProvider(''))
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text('$error'),
                data: (sets) => Column(
                  children: sets
                      .map(
                        (set) => Card(
                          child: ListTile(
                            title: Text(set.title),
                            subtitle: Text(
                              set.cardCount < 4
                                  ? 'Cần tối thiểu 4 thẻ'
                                  : '${set.cardCount} câu hỏi - làm bài',
                            ),
                            trailing: const Icon(Icons.play_arrow),
                            enabled: set.cardCount >= 4,
                            onTap: () async {
                              final questions = await ref
                                  .read(repositoryProvider)
                                  .generateQuiz(set.id);
                              if (!context.mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _QuizRunPage(
                                    set: set,
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
                ),
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
    required this.set,
    required this.questions,
    required this.userId,
  });

  final FlashcardSet set;
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
      appBar: AppBar(title: Text(widget.set.title)),
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
            widget.set.id,
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

String _answerOrderLabel(String value) {
  return value == 'random' ? 'Ngẫu nhiên' : 'Cố định';
}

String _className(List<Classroom> classes, String? classId) {
  if (classId == null) return 'Chưa chọn lớp';
  for (final item in classes) {
    if (item.id == classId) return item.name;
  }
  return 'Lớp không còn tồn tại';
}
