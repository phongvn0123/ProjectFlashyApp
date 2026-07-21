import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/colors.dart';
import '../pages/classroom_study_page.dart';
import '../providers/classroom_providers.dart';

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String? _formatIsoDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final date = DateTime.tryParse(iso);
  if (date == null) return null;
  return _formatDate(date);
}

class ClassroomSetsTab extends ConsumerWidget {
  const ClassroomSetsTab({
    super.key,
    required this.classId,
    required this.isTeacher,
    required this.user,
    this.header,
  });

  final String classId;
  final bool isTeacher;
  final AppUser? user;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedAsync = ref.watch(assignedSetsProvider(classId));

    return assignedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (items) {
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                if (header != null) ...[
                  header!,
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bộ thẻ đã giao (${items.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.filter_list, color: AppColors.kOutline),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('Chưa có bộ thẻ nào được giao'),
                    ),
                  ),
                for (final item in items)
                  _AssignedSetCard(
                    item: item,
                    isTeacher: isTeacher,
                    onTap: user == null
                        ? null
                        : () => _openStudy(context, ref, item, user!),
                    onRemove: isTeacher && user != null
                        ? () => _unassign(context, ref, item, user!)
                        : null,
                  ),
                if (isTeacher) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: user == null
                        ? null
                        : () => _assignSet(context, ref, user!),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Thêm bộ thẻ mới - Giao từ thư viện của bạn',
                    ),
                  ),
                ],
              ],
            ),
            if (isTeacher && user != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: FilledButton.icon(
                    onPressed: () => _assignSet(context, ref, user!),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Giao bộ thẻ'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openStudy(
    BuildContext context,
    WidgetRef ref,
    AssignedSetItem item,
    AppUser user,
  ) async {
    final cards = await ref.read(repositoryProvider).cards(item.setId);
    if (!context.mounted) return;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bộ thẻ chưa có flashcard')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassroomStudyPage(
          assigned: item,
          cards: cards,
          userId: user.id,
        ),
      ),
    );
    invalidateClassroomData(ref, classId: classId, userId: user.id);
  }

  Future<void> _assignSet(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final sets = await ref.read(repositoryProvider).sets();
    if (!context.mounted) return;
    if (sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thư viện chưa có bộ thẻ')),
      );
      return;
    }

    FlashcardSet? selected = sets.first;
    String? selectedId = sets.first.id;
    DateTime? dueAt = DateTime.now().add(const Duration(days: 7));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Giao bộ thẻ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedId,
                    items: [
                      for (final set in sets)
                        DropdownMenuItem(
                          value: set.id,
                          child: Text(set.title),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedId = value;
                        selected = sets.firstWhere((s) => s.id == value);
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Bộ thẻ'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hạn hoàn thành'),
                    subtitle: Text(
                      dueAt == null
                          ? 'Không đặt hạn'
                          : _formatDate(dueAt!),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueAt ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setState(() => dueAt = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Giao'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selected == null) return;
    await ref.read(repositoryProvider).assignSet(
      classId: classId,
      setId: selected!.id,
      assignedById: user.id,
      dueAt: dueAt,
    );
    invalidateClassroomData(ref, classId: classId, userId: user.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã giao bộ thẻ')),
    );
  }

  Future<void> _unassign(
    BuildContext context,
    WidgetRef ref,
    AssignedSetItem item,
    AppUser user,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gỡ bộ thẻ?'),
        content: Text('Gỡ "${item.setTitle}" khỏi lớp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Gỡ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).unassignSet(item.id, user.id);
    invalidateClassroomData(ref, classId: classId, userId: user.id);
  }
}

class _AssignedSetCard extends StatelessWidget {
  const _AssignedSetCard({
    required this.item,
    required this.isTeacher,
    this.onTap,
    this.onRemove,
  });

  final AssignedSetItem item;
  final bool isTeacher;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final status = item.statusLabel;
    final isCompleted = status == 'completed';
    final badgeColor = switch (status) {
      'nearing' => const Color(0xFFE91E63),
      'completed' => AppColors.kPrimary,
      _ => AppColors.kOutline,
    };
    final badgeText = switch (status) {
      'nearing' => 'GẦN ĐẾN HẠN',
      'completed' => 'HOÀN THÀNH',
      _ => 'ĐANG DIỄN RA',
    };
    final dueText = _formatIsoDate(item.dueAt) ?? 'Không hạn';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isCompleted ? AppColors.kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isCompleted
                  ? null
                  : Border.all(color: AppColors.kOutlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.white24
                            : badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isCompleted ? Colors.white : badgeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isTeacher && onRemove != null)
                      IconButton(
                        onPressed: onRemove,
                        icon: Icon(
                          Icons.more_vert,
                          color: isCompleted
                              ? Colors.white70
                              : AppColors.kOutline,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        color: isCompleted
                            ? Colors.white70
                            : AppColors.kOutline,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.setTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isCompleted ? Colors.white : AppColors.kOnSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.cardCount} thuật ngữ'
                  '${onTap != null ? ' · Chạm để học' : ''}',
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.white70
                        : AppColors.kOnSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: item.progressRatio.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isCompleted
                        ? Colors.white24
                        : AppColors.kSurfaceContainerHigh,
                    color: isCompleted
                        ? Colors.white
                        : AppColors.kPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${item.completedCount}/${item.studentCount} học sinh',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? Colors.white
                            : AppColors.kOnSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isCompleted ? 'Đã đóng hạn chót' : dueText,
                      style: TextStyle(
                        color: isCompleted
                            ? Colors.white70
                            : AppColors.kOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
