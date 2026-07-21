import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../providers/classroom_providers.dart';

class ClassroomActivityTab extends ConsumerWidget {
  const ClassroomActivityTab({
    super.key,
    required this.classId,
    required this.isTeacher,
    this.header,
    this.onAssignSet,
  });

  final String classId;
  final bool isTeacher;
  final Widget? header;
  final VoidCallback? onAssignSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(classActivitiesProvider(classId));
    final rateAsync = ref.watch(classCompletionRateProvider(classId));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(height: 16),
            ],
            const Text(
              'Dòng thời gian',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            activitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('$error'),
              data: (activities) {
                if (activities.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('Chưa có hoạt động nào'),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final activity in activities)
                      _ActivityTile(
                        title: '${activity.actorName} ${activity.message}',
                        timeLabel: _relativeTime(activity.timestamp),
                        icon: _iconFor(activity.action),
                        color: _colorFor(activity.action),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            rateAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (rate) {
                final percent = (rate * 100).round();
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tỷ lệ hoàn thành bộ thẻ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.kPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: rate.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: AppColors.kSurfaceContainerHigh,
                            color: AppColors.kPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Lớp đang có sự tiến bộ ổn định trong tháng này',
                          style: TextStyle(
                            color: AppColors.kOnSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        if (isTeacher && onAssignSet != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: FloatingActionButton.extended(
                onPressed: onAssignSet,
                backgroundColor: AppColors.kPrimaryContainer,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Giao bộ thẻ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconFor(String action) {
    return switch (action) {
      'assign_set' => Icons.assignment_turned_in_outlined,
      'complete_set' => Icons.check_circle_outline,
      'join' => Icons.person_add_alt_1,
      'leave' || 'remove_member' => Icons.person_remove_outlined,
      'create_class' => Icons.school_outlined,
      _ => Icons.notifications_none,
    };
  }

  static Color _colorFor(String action) {
    return switch (action) {
      'assign_set' => AppColors.kPrimaryContainer,
      'complete_set' => const Color(0xFF2E7D32),
      'join' => const Color(0xFF8D6E63),
      _ => AppColors.kOutline,
    };
  }

  static String _relativeTime(String iso) {
    final time = DateTime.tryParse(iso);
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    return '${diff.inDays} ngày trước';
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.timeLabel,
    required this.icon,
    required this.color,
  });

  final String title;
  final String timeLabel;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: AppColors.kOutline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
