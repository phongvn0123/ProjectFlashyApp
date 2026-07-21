import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/colors.dart';
import '../providers/classroom_providers.dart';

class ClassroomStudyPage extends ConsumerStatefulWidget {
  const ClassroomStudyPage({
    super.key,
    required this.assigned,
    required this.cards,
    required this.userId,
  });

  final AssignedSetItem assigned;
  final List<Flashcard> cards;
  final String userId;

  @override
  ConsumerState<ClassroomStudyPage> createState() => _ClassroomStudyPageState();
}

class _ClassroomStudyPageState extends ConsumerState<ClassroomStudyPage> {
  int _index = 0;
  int _known = 0;
  int _unknown = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.assigned.setTitle)),
        body: const Center(child: Text('Bộ thẻ trống.')),
      );
    }

    final done = _index >= widget.cards.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.assigned.setTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: done ? _buildResult() : _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    final card = widget.cards[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_index + 1}/${widget.cards.length} · Thuộc $_known · Chưa thuộc $_unknown',
        ),
        const SizedBox(height: 16),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _showBack = !_showBack),
            child: Card(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _showBack ? card.back : card.front,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chạm thẻ để lật',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.kOutline),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _next(false),
                child: const Text('Chưa thuộc'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _next(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryContainer,
                ),
                child: const Text('Đã thuộc'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult() {
    return _StudyResult(
      assigned: widget.assigned,
      userId: widget.userId,
      known: _known,
      unknown: _unknown,
    );
  }

  void _next(bool known) {
    setState(() {
      if (known) {
        _known++;
      } else {
        _unknown++;
      }
      _index++;
      _showBack = false;
    });
  }
}

class _StudyResult extends ConsumerStatefulWidget {
  const _StudyResult({
    required this.assigned,
    required this.userId,
    required this.known,
    required this.unknown,
  });

  final AssignedSetItem assigned;
  final String userId;
  final int known;
  final int unknown;

  @override
  ConsumerState<_StudyResult> createState() => _StudyResultState();
}

class _StudyResultState extends ConsumerState<_StudyResult> {
  bool _saving = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_saveProgress);
  }

  Future<void> _saveProgress() async {
    final repo = ref.read(repositoryProvider);
    await repo.saveLearningResult(
      userId: widget.userId,
      setId: widget.assigned.setId,
      known: widget.known,
      unknown: widget.unknown,
    );
    await repo.markAssignmentCompleted(
      assignedSetId: widget.assigned.id,
      userId: widget.userId,
      classId: widget.assigned.classId,
    );
    invalidateClassroomData(
      ref,
      classId: widget.assigned.classId,
      userId: widget.userId,
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _saved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Kết quả buổi học',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Text('Đã thuộc: ${widget.known}'),
        Text('Chưa thuộc: ${widget.unknown}'),
        const SizedBox(height: 12),
        if (_saving)
          const CircularProgressIndicator()
        else if (_saved)
          const Text(
            'Đã ghi nhận tiến độ hoàn thành cho lớp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.kPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.kPrimaryContainer,
          ),
          child: const Text('Hoàn thành'),
        ),
      ],
    );
  }
}
