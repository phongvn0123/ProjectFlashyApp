import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';

class StudentQuizPage extends ConsumerStatefulWidget {
  const StudentQuizPage({required this.user, super.key});

  final AppUser user;

  @override
  ConsumerState<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends ConsumerState<StudentQuizPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(
      studentQuizAssignmentsProvider(widget.user.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bài kiểm tra',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentQuizAssignmentsProvider(widget.user.id));
          await ref.read(studentQuizAssignmentsProvider(widget.user.id).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm bài kiểm tra theo tiêu đề',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 16),
            assignments.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Không thể tải danh sách bài kiểm tra'),
                  subtitle: Text('$error'),
                ),
              ),
              data: _buildQuizList,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList(List<StudentAssignedQuiz> assignments) {
    final normalizedQuery = _query.toLowerCase();
    final filtered = assignments
        .where(
          (assignment) =>
              assignment.quiz.title.toLowerCase().contains(normalizedQuery),
        )
        .toList();

    if (assignments.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.assignment_outlined),
          title: Text('Chưa có bài kiểm tra nào được giao'),
        ),
      );
    }
    if (filtered.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.search_off),
          title: Text('Không tìm thấy bài kiểm tra phù hợp'),
        ),
      );
    }

    final upcoming = filtered.where((item) => !item.isCompleted).toList();
    final completed = filtered.where((item) => item.isCompleted).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Sắp tới', count: upcoming.length),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const _EmptySection(message: 'Không còn bài kiểm tra cần làm')
        else
          ...upcoming.map(
            (item) => _UpcomingQuizCard(
              assignment: item,
              onOpen: () => _openDetail(item),
            ),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF0759A7), Color(0xFF0B3F7D)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mẹo học tập', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text(
                'Đọc kỹ câu hỏi và hoàn thành bài trước khi hết thời gian.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionHeader(title: 'Đã hoàn thành', count: completed.length),
        const SizedBox(height: 10),
        if (completed.isEmpty)
          const _EmptySection(message: 'Bạn chưa hoàn thành bài kiểm tra nào')
        else
          ...completed.map(
            (item) => _CompletedQuizTile(
              assignment: item,
              onOpen: () => _openDetail(item),
            ),
          ),
      ],
    );
  }

  Future<void> _openDetail(StudentAssignedQuiz assignment) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentQuizDetailPage(
          assignment: assignment,
          studentId: widget.user.id,
        ),
      ),
    );
    ref.invalidate(studentQuizAssignmentsProvider(widget.user.id));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count bài'),
        ),
      ],
    );
  }
}

class _UpcomingQuizCard extends StatelessWidget {
  const _UpcomingQuizCard({required this.assignment, required this.onOpen});

  final StudentAssignedQuiz assignment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final quiz = assignment.quiz;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_outlined, size: 20),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    assignment.classroomName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              quiz.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text('Giáo viên: ${assignment.teacherName}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.format_list_numbered, size: 16),
                const SizedBox(width: 4),
                Text('${quiz.questionCount} câu'),
                const SizedBox(width: 16),
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text('${quiz.timeLimitMinutes} phút'),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: const Text('Bắt đầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedQuizTile extends StatelessWidget {
  const _CompletedQuizTile({required this.assignment, required this.onOpen});

  final StudentAssignedQuiz assignment;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final score = assignment.latestScore;
    final total = assignment.latestTotal;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.check_circle_outline),
        ),
        title: Text(assignment.quiz.title),
        subtitle: Text(assignment.classroomName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (score != null && total != null) Text('$score/$total'),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class StudentQuizDetailPage extends ConsumerWidget {
  const StudentQuizDetailPage({
    required this.assignment,
    required this.studentId,
    super.key,
  });

  final StudentAssignedQuiz assignment;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = assignment.quiz;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài kiểm tra')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(quiz.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _InfoTile(label: 'Giáo viên', value: assignment.teacherName),
                _InfoTile(label: 'Lớp học', value: assignment.classroomName),
                const _InfoTile(
                  label: 'Trạng thái khả dụng',
                  value: 'Đang mở',
                  valueColor: Colors.green,
                ),
                _InfoTile(
                  label: 'Trạng thái hoàn thành',
                  value: assignment.isCompleted ? 'Đã làm' : 'Chưa làm',
                ),
                _InfoTile(label: 'Số câu hỏi', value: '${quiz.questionCount}'),
                _InfoTile(
                  label: 'Thời gian làm bài',
                  value: '${quiz.timeLimitMinutes} phút',
                ),
                _InfoTile(
                  label: 'Thứ tự câu hỏi',
                  value: quiz.questionOrder == 'random'
                      ? 'Ngẫu nhiên'
                      : 'Tuần tự',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: assignment.isCompleted
                ? null
                : () => _startQuiz(context, ref),
            icon: Icon(
              assignment.isCompleted ? Icons.check_circle : Icons.play_arrow,
            ),
            label: Text(
              assignment.isCompleted
                  ? 'Đã hoàn thành bài kiểm tra'
                  : 'Bắt đầu làm bài',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz(BuildContext context, WidgetRef ref) async {
    final quiz = assignment.quiz;
    QuizAttemptSession session;
    try {
      session = await ref
          .read(repositoryProvider)
          .startQuizAttempt(userId: studentId, quiz: quiz);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
      ref.invalidate(studentQuizAssignmentsProvider(studentId));
      return;
    }
    final storedQuestions = await ref
        .read(repositoryProvider)
        .quizQuestions(quiz.id);
    final questions = storedQuestions
        .map(
          (question) => QuizQuestion(
            id: question.id,
            prompt: question.prompt,
            options: question.options.isEmpty
                ? [question.correctAnswer]
                : question.options,
            correctIndex: question.options.isEmpty ? 0 : question.correctIndex,
          ),
        )
        .toList();
    if (quiz.questionOrder == 'random') questions.shuffle();
    if (!context.mounted) return;

    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StudentQuizRunPage(
          assignment: assignment,
          studentId: studentId,
          questions: questions,
          session: session,
        ),
      ),
    );
    ref.invalidate(studentQuizAssignmentsProvider(studentId));
    ref.invalidate(quizHistoryProvider(studentId));
    if (completed == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentQuizRunPage extends ConsumerStatefulWidget {
  const StudentQuizRunPage({
    required this.assignment,
    required this.studentId,
    required this.questions,
    required this.session,
    super.key,
  });

  final StudentAssignedQuiz assignment;
  final String studentId;
  final List<QuizQuestion> questions;
  final QuizAttemptSession session;

  @override
  ConsumerState<StudentQuizRunPage> createState() => _StudentQuizRunPageState();
}

class _StudentQuizRunPageState extends ConsumerState<StudentQuizRunPage>
    with WidgetsBindingObserver {
  int _index = 0;
  late final List<int?> _answers;
  bool _done = false;
  bool _submitting = false;
  bool _automaticallySubmitted = false;
  Timer? _timer;
  late final DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.questions.length, null);
    WidgetsBinding.instance.addObserver(this);
    _deadline = widget.session.startedAt.add(
      Duration(minutes: widget.assignment.quiz.timeLimitMinutes),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAutoSubmit());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleAutoSubmit();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Bài kiểm tra chưa có câu hỏi.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Đóng',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.close),
        ),
        title: Text(
          'Câu ${_index + 1}/${widget.questions.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Trợ giúp',
            icon: const Icon(Icons.help_outline),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_index + 1) / widget.questions.length,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
        child: _done ? _buildResult() : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final question = widget.questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.prompt,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('Chọn câu trả lời đúng nhất.', textAlign: TextAlign.center),
        const SizedBox(height: 28),
        for (
          var optionIndex = 0;
          optionIndex < question.options.length;
          optionIndex++
        )
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: _submitting
                  ? null
                  : () => setState(() => _answers[_index] = optionIndex),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                side: BorderSide(
                  width: _answers[_index] == optionIndex ? 2 : 1,
                  color: _answers[_index] == optionIndex
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _answers[_index] == optionIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor: _answers[_index] == optionIndex
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    child: Text(String.fromCharCode(65 + optionIndex)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.options[optionIndex],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_answers[_index] == optionIndex)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        const Spacer(),
        Row(
          children: [
            TextButton.icon(
              onPressed: _index == 0 || _submitting
                  ? null
                  : () => setState(() => _index--),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Trước'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _answers[_index] == null || _submitting
                  ? null
                  : _goNext,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _index == widget.questions.length - 1 ? 'Nộp bài' : 'Tiếp',
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Kết quả bài kiểm tra',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text('Điểm: $_score/${widget.questions.length}'),
        if (_automaticallySubmitted) ...[
          const SizedBox(height: 8),
          const Text(
            'Đã hết thời gian. Hệ thống đã tự động nộp bài.',
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hoàn thành'),
        ),
      ],
    );
  }

  int get _score {
    var score = 0;
    for (var index = 0; index < widget.questions.length; index++) {
      if (_answers[index] == widget.questions[index].correctIndex) score++;
    }
    return score;
  }

  Future<void> _goNext() async {
    if (_submitting || _done) return;
    if (_index < widget.questions.length - 1) {
      setState(() => _index++);
      return;
    }

    await _submit();
  }

  void _scheduleAutoSubmit() {
    if (!mounted || _done || _submitting) return;
    _timer?.cancel();
    final remaining = _deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _submit(automatically: true);
      return;
    }
    _timer = Timer(remaining, () => _submit(automatically: true));
  }

  Future<void> _submit({bool automatically = false}) async {
    if (_submitting || _done) return;
    _submitting = true;
    _timer?.cancel();
    try {
      await ref
          .read(repositoryProvider)
          .completeQuizAttempt(
            attemptId: widget.session.id,
            score: _score,
            total: widget.questions.length,
            questions: widget.questions,
            selectedAnswers: _answers,
          );
      if (!mounted) return;
      setState(() {
        _done = true;
        _automaticallySubmitted = automatically;
      });
      if (automatically) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hết thời gian. Hệ thống đã tự động nộp bài.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _submitting = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể nộp bài: $error')));
      _timer = Timer(const Duration(seconds: 1), _scheduleAutoSubmit);
    }
  }
}
