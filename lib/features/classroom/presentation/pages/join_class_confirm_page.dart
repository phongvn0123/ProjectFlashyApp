import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/colors.dart';
import '../providers/classroom_providers.dart';
import 'classroom_detail_page.dart';

class JoinClassConfirmPage extends ConsumerStatefulWidget {
  const JoinClassConfirmPage({
    super.key,
    required this.preview,
    required this.user,
  });

  final ClassroomPreview preview;
  final AppUser user;

  @override
  ConsumerState<JoinClassConfirmPage> createState() =>
      _JoinClassConfirmPageState();
}

class _JoinClassConfirmPageState extends ConsumerState<JoinClassConfirmPage> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final classroom = preview.classroom;
    final displayName = widget.user.fullName.isNotEmpty
        ? widget.user.fullName
        : widget.user.username;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tuyệt vời!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chúng tôi đã tìm thấy lớp học của bạn. Hãy xác nhận các thông tin dưới đây để bắt đầu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.kOnSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.kSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.kPrimaryContainer
                                    .withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.menu_book,
                                  color: AppColors.kPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LỚP HỌC',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.kPrimaryContainer,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      classroom.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _InfoTile(
                            icon: Icons.person_outline,
                            label: 'GIẢNG VIÊN',
                            value: preview.teacherName,
                          ),
                          const SizedBox(height: 8),
                          _InfoTile(
                            icon: Icons.bar_chart_outlined,
                            label: 'TỔNG QUAN',
                            value:
                                '${preview.studentCount} học sinh • ${preview.setCount} bộ thẻ',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.kPrimaryFixed,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text.rich(
                        TextSpan(
                          text: 'Tham gia với tên ',
                          children: [
                            TextSpan(
                              text: displayName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _joining ? null : _confirmJoin,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _joining
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Xác nhận tham gia'),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right),
                              ],
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: _joining
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bằng cách tham gia, bạn đồng ý với nội quy lớp học và chính sách bảo mật của chúng tôi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.kOutline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmJoin() async {
    setState(() => _joining = true);
    try {
      final classroom = await ref
          .read(repositoryProvider)
          .joinClass(
            widget.user.id,
            widget.preview.classroom.joinCode,
          );
      if (!mounted) return;
      if (classroom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tham gia lớp')),
        );
        setState(() => _joining = false);
        return;
      }
      invalidateClassroomData(
        ref,
        userId: widget.user.id,
        classId: classroom.id,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClassroomDetailPage(classId: classroom.id),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
      setState(() => _joining = false);
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.kOutline, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.kOutline,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
