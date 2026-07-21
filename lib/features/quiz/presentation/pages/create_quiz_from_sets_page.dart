import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';

class CreateQuizFromSetsPage extends ConsumerStatefulWidget {
  const CreateQuizFromSetsPage({
    required this.teacher,
    required this.sets,
    super.key,
  });

  final AppUser teacher;
  final List<FlashcardSet> sets;

  @override
  ConsumerState<CreateQuizFromSetsPage> createState() =>
      _CreateQuizFromSetsPageState();
}

class _CreateQuizFromSetsPageState
    extends ConsumerState<CreateQuizFromSetsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '15');
  final _questionCountController = TextEditingController(text: '10');
  final Set<String> _selectedSetIds = {};

  String _questionOrder = 'sequential';
  List<QuizQuestion> _previewQuestions = const [];
  bool _isGenerating = false;
  bool _isSaving = false;

  int get _availableCardCount => widget.sets
      .where((set) => _selectedSetIds.contains(set.id))
      .fold(0, (total, set) => total + set.cardCount);

  @override
  void initState() {
    super.initState();
    _questionCountController.addListener(_clearPreviewAfterConfigurationChange);
  }

  @override
  void dispose() {
    _questionCountController.removeListener(
      _clearPreviewAfterConfigurationChange,
    );
    _titleController.dispose();
    _timeLimitController.dispose();
    _questionCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo bài kiểm tra')),
      bottomNavigationBar: _previewQuestions.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveDraft,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Lưu bài kiểm tra'),
                ),
              ),
            ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '1. Chọn nguồn bộ thẻ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (widget.sets.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Chưa có bộ thẻ để tạo bài kiểm tra'),
                ),
              )
            else
              ...widget.sets.map(_buildSetTile),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Đã chọn ${_selectedSetIds.length} bộ thẻ • '
                '$_availableCardCount thẻ khả dụng',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '2. Cấu hình bài kiểm tra',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề bài kiểm tra',
                hintText: 'Ví dụ: Kiểm tra từ vựng tuần 1',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề bài kiểm tra';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _timeLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thời gian làm bài (phút)',
              ),
              validator: (value) {
                final minutes = int.tryParse(value?.trim() ?? '');
                if (minutes == null || minutes < 1 || minutes > 180) {
                  return 'Thời gian phải từ 1 đến 180 phút';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _questionCountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số câu hỏi',
                helperText: _availableCardCount == 0
                    ? 'Chọn bộ thẻ trước'
                    : 'Tối đa $_availableCardCount câu',
              ),
              validator: (value) {
                final count = int.tryParse(value?.trim() ?? '');
                if (_selectedSetIds.isEmpty) {
                  return 'Vui lòng chọn ít nhất một bộ thẻ';
                }
                if (_availableCardCount < 4) {
                  return 'Nguồn cần có ít nhất 4 thẻ để tạo câu trắc nghiệm';
                }
                if (count == null || count < 1 || count > _availableCardCount) {
                  return 'Số câu phải từ 1 đến $_availableCardCount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _questionOrder,
              decoration: const InputDecoration(labelText: 'Thứ tự câu hỏi'),
              items: const [
                DropdownMenuItem(value: 'sequential', child: Text('Tuần tự')),
                DropdownMenuItem(value: 'random', child: Text('Ngẫu nhiên')),
              ],
              onChanged: (value) {
                setState(() {
                  _questionOrder = value ?? 'sequential';
                  _previewQuestions = const [];
                });
              },
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isGenerating || _isSaving ? null : _generateQuiz,
              icon: _isGenerating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Tạo câu hỏi và xem trước'),
            ),
            if (_previewQuestions.isNotEmpty) ...[
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '3. Xem trước câu hỏi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${_previewQuestions.length} câu'),
                ],
              ),
              const SizedBox(height: 8),
              ..._previewQuestions.indexed.map(
                (entry) => _QuestionPreviewCard(
                  number: entry.$1 + 1,
                  question: entry.$2,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetTile(FlashcardSet set) {
    return Card(
      child: CheckboxListTile(
        value: _selectedSetIds.contains(set.id),
        title: Text(set.title),
        subtitle: Text('${set.cardCount} thẻ • ${set.description}'),
        onChanged: (selected) {
          setState(() {
            if (selected ?? false) {
              _selectedSetIds.add(set.id);
              if (_titleController.text.trim().isEmpty) {
                _titleController.text = 'Kiểm tra: ${set.title}';
              }
            } else {
              _selectedSetIds.remove(set.id);
            }
            _previewQuestions = const [];
          });
        },
      ),
    );
  }

  void _clearPreviewAfterConfigurationChange() {
    if (_previewQuestions.isEmpty || !mounted) return;
    setState(() => _previewQuestions = const []);
  }

  Future<void> _generateQuiz() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isGenerating = true);
    try {
      final questions = await ref
          .read(repositoryProvider)
          .generateQuizFromSets(
            setIds: _selectedSetIds.toList(),
            questionCount: int.parse(_questionCountController.text.trim()),
            questionOrder: _questionOrder,
          );
      if (!mounted) return;
      if (questions.isEmpty) {
        _showMessage('Không thể tạo câu hỏi từ các bộ thẻ đã chọn.');
        return;
      }
      setState(() => _previewQuestions = questions);
      _showMessage(
        'Đã tạo ${questions.length} câu hỏi. Hãy kiểm tra bản xem trước rồi bấm Lưu bài kiểm tra.',
      );
    } catch (error) {
      if (mounted) _showMessage('Không thể tạo câu hỏi: $error');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveDraft() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final expectedCount = int.parse(_questionCountController.text.trim());
    if (_previewQuestions.length != expectedCount) {
      _showMessage('Cấu hình đã thay đổi. Vui lòng tạo lại câu hỏi.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(repositoryProvider)
          .createQuiz(
            teacherId: widget.teacher.id,
            setIds: _selectedSetIds.toList(),
            title: _titleController.text,
            timeLimitMinutes: int.parse(_timeLimitController.text.trim()),
            questionOrder: _questionOrder,
            questions: _previewQuestions,
          );
      ref.invalidate(teacherQuizzesProvider);
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Không thể lưu bài kiểm tra: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  const _QuestionPreviewCard({required this.number, required this.question});

  final int number;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu $number. ${question.prompt}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...question.options.indexed.map((entry) {
              final isCorrect = entry.$1 == question.correctIndex;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isCorrect ? Icons.check_circle : Icons.circle_outlined,
                  color: isCorrect ? Colors.green : null,
                ),
                title: Text(entry.$2),
                subtitle: isCorrect ? const Text('Đáp án đúng') : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
