import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/colors.dart';
import 'classroom_detail_page.dart';
import 'join_class_confirm_page.dart';
import '../providers/classroom_providers.dart';
import '../widgets/classroom_text_dialog.dart';

class ClassroomPage extends ConsumerWidget {
  const ClassroomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref
        .watch(authControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final canManage = user?.role == 'teacher' || user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: user == null
          ? const Center(child: Text('Đăng nhập để xem lớp học.'))
          : ref
                .watch(classroomProvider(user.id))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('$error')),
                  data: (classes) => _ClassroomListBody(
                    user: user,
                    classes: classes,
                    canManage: canManage,
                  ),
                ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (canManage) {
                  _showCreateClassDialog(context, ref, user);
                } else {
                  _showJoinCodeDialog(context, ref, user);
                }
              },
              backgroundColor: AppColors.kPrimaryContainer,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}

class _ClassroomListBody extends ConsumerWidget {
  const _ClassroomListBody({
    required this.user,
    required this.classes,
    required this.canManage,
  });

  final AppUser user;
  final List<Classroom> classes;
  final bool canManage;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String get _displayName {
    if (user.fullName.isNotEmpty) {
      final parts = user.fullName.trim().split(RegExp(r'\s+'));
      return parts.isNotEmpty ? parts.last : user.fullName;
    }
    return user.username;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (canManage)
                    IconButton(
                      onPressed: () =>
                          _showCreateClassDialog(context, ref, user),
                      icon: const Icon(Icons.add),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Lớp học',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HỌC TẬP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.kPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_greeting, $_displayName.',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (canManage) {
                          _showCreateClassDialog(context, ref, user);
                        } else {
                          _showJoinCodeDialog(context, ref, user);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(canManage ? Icons.add : Icons.login),
                      label: Text(
                        canManage ? 'Tạo lớp mới' : 'Tham gia lớp mới',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (classes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _DashedJoinCard(
                  onTap: () {
                    if (canManage) {
                      _showCreateClassDialog(context, ref, user);
                    } else {
                      _showJoinCodeDialog(context, ref, user);
                    }
                  },
                  title: canManage ? 'Tạo lớp mới' : 'Tham gia lớp mới',
                  subtitle: canManage
                      ? 'Tạo lớp và chia sẻ mã tham gia cho học sinh'
                      : 'Nhập mã lớp để bắt đầu hành trình học tập mới',
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _FeaturedClassCard(
                  classroom: classes.first,
                  onTap: () => _openDetail(context, classes.first),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = classes[index + 1];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _ClassListCard(
                    classroom: item,
                    accentIndex: index,
                    onTap: () => _openDetail(context, item),
                  ),
                );
              }, childCount: (classes.length - 1).clamp(0, classes.length)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                child: _DashedJoinCard(
                  onTap: () {
                    if (canManage) {
                      _showCreateClassDialog(context, ref, user);
                    } else {
                      _showJoinCodeDialog(context, ref, user);
                    }
                  },
                  title: canManage ? 'Tạo lớp mới' : 'Tham gia lớp mới',
                  subtitle: canManage
                      ? 'Tạo lớp và chia sẻ mã tham gia cho học sinh'
                      : 'Nhập mã lớp để bắt đầu hành trình học tập mới',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Classroom classroom) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassroomDetailPage(classId: classroom.id),
      ),
    );
  }
}

class _FeaturedClassCard extends StatelessWidget {
  const _FeaturedClassCard({required this.classroom, required this.onTap});

  final Classroom classroom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3A6B), Color(0xFF0D1B2A)],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Đang diễn ra',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                classroom.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mã lớp: ${classroom.joinCode}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nhấn để xem chi tiết',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassListCard extends StatelessWidget {
  const _ClassListCard({
    required this.classroom,
    required this.accentIndex,
    required this.onTap,
  });

  final Classroom classroom;
  final int accentIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accents = [
      const Color(0xFFFF8A3D),
      const Color(0xFF5B9BD5),
      const Color(0xFF6BBF8A),
    ];
    final color = accents[accentIndex % accents.length];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.menu_book_outlined, color: color),
        ),
        title: Text(
          classroom.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('Mã lớp: ${classroom.joinCode}'),
        trailing: Icon(
          classroom.isJoinEnabled ? Icons.lock_open : Icons.lock,
          color: AppColors.kOutline,
        ),
      ),
    );
  }
}

class _DashedJoinCard extends StatelessWidget {
  const _DashedJoinCard({
    required this.onTap,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.kOutlineVariant,
          radius: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kPrimaryContainer.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.kPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.kOnSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    final dashed = _dashPath(path, dashWidth: 6, dashSpace: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source, {required double dashWidth, required double dashSpace}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dest.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _showCreateClassDialog(
  BuildContext context,
  WidgetRef ref,
  AppUser user,
) async {
  final name = await showClassroomTextDialog(
    context: context,
    title: 'Tạo lớp học',
    label: 'Tên lớp học',
    hint: 'Ví dụ: Lớp 12A - Tiếng Anh',
    confirmLabel: 'Tạo',
  );
  if (name == null || name.isEmpty || !context.mounted) return;

  final created = await ref.read(repositoryProvider).createClass(user.id, name);
  if (!context.mounted) return;

  invalidateClassroomData(ref, userId: user.id, classId: created.id);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Tạo lớp thành công'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lớp "${created.name}" đã được tạo.'),
          const SizedBox(height: 12),
          const Text(
            'Mã tham gia (hệ thống tự sinh):',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SelectableText(
            created.joinCode,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: AppColors.kPrimaryContainer,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: created.joinCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã sao chép mã lớp')),
            );
          },
          child: const Text('Sao chép mã'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

Future<void> _showJoinCodeDialog(
  BuildContext context,
  WidgetRef ref,
  AppUser user,
) async {
  final code = await showClassroomTextDialog(
    context: context,
    title: 'Nhập mã lớp',
    label: 'Mã tham gia',
    hint: '6 chữ số',
    confirmLabel: 'Tiếp tục',
    keyboardType: TextInputType.number,
  );
  if (code == null || code.isEmpty || !context.mounted) return;

  final preview = await ref.read(repositoryProvider).previewJoinByCode(code);
  if (!context.mounted) return;
  if (preview == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không tìm thấy lớp hoặc mã đã bị khóa'),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => JoinClassConfirmPage(preview: preview, user: user),
    ),
  );
}
