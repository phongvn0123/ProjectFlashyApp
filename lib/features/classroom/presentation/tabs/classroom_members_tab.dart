import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/colors.dart';
import '../providers/classroom_providers.dart';
import '../widgets/classroom_text_dialog.dart';

class ClassroomMembersTab extends ConsumerStatefulWidget {
  const ClassroomMembersTab({
    super.key,
    required this.classId,
    required this.isTeacher,
    required this.user,
    required this.classroom,
    this.header,
  });

  final String classId;
  final bool isTeacher;
  final AppUser? user;
  final Classroom classroom;
  final Widget? header;

  @override
  ConsumerState<ClassroomMembersTab> createState() =>
      _ClassroomMembersTabState();
}

class _ClassroomMembersTabState extends ConsumerState<ClassroomMembersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(classMembersProvider(widget.classId));

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (members) {
        final students = members
            .where((m) => m.role == 'student')
            .where((m) {
              if (_query.trim().isEmpty) return true;
              final q = _query.trim().toLowerCase();
              return m.displayName.toLowerCase().contains(q) ||
                  m.email.toLowerCase().contains(q);
            })
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Danh sách học sinh (${students.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Tìm thành viên...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  if (widget.header != null) ...[
                    widget.header!,
                    const SizedBox(height: 12),
                  ],
                  for (final member in students)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.kPrimaryFixed,
                          child: Text(
                            member.displayName.isNotEmpty
                                ? member.displayName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(
                          '${member.displayName} (Student)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(member.email),
                        trailing: widget.isTeacher
                            ? PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'remove') {
                                    await _removeMember(member);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Xóa thành viên'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  if (widget.isTeacher)
                    _DashedInviteCard(onTap: _inviteByEmail),
                  if (widget.isTeacher)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryFixed.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.kPrimaryContainer,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quản lý lớp học',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Với tư cách là giáo viên, bạn có quyền thêm hoặc xóa thành viên khỏi lớp học này.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.kOnSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!widget.isTeacher && widget.user != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: _leaveClass,
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Rời lớp học'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isTeacher)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _inviteByEmail,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Thêm thành viên'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _inviteByEmail() async {
    final user = widget.user;
    if (user == null) return;
    final email = await showClassroomTextDialog(
      context: context,
      title: 'Thêm thành viên',
      label: 'Email học sinh',
      hint: 'student@memocard.test',
      confirmLabel: 'Thêm',
      keyboardType: TextInputType.emailAddress,
    );
    if (email == null || email.isEmpty || !mounted) return;
    try {
      await ref.read(repositoryProvider).addMemberByEmail(
        classId: widget.classId,
        email: email,
        actorId: user.id,
      );
      invalidateClassroomData(
        ref,
        classId: widget.classId,
        userId: user.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm thành viên')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _removeMember(ClassMember member) async {
    final user = widget.user;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa thành viên?'),
        content: Text('Xóa ${member.displayName} khỏi lớp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).removeMember(
        classId: widget.classId,
        userId: member.userId,
        actorId: user.id,
      );
      invalidateClassroomData(
        ref,
        classId: widget.classId,
        userId: user.id,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _leaveClass() async {
    final user = widget.user;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rời lớp học?'),
        content: Text('Bạn sẽ rời "${widget.classroom.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Rời lớp'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repositoryProvider).leaveClass(
        classId: widget.classId,
        userId: user.id,
      );
      invalidateClassroomData(ref, userId: user.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _DashedInviteCard extends StatelessWidget {
  const _DashedInviteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.kOutlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.person_add_alt_1, color: AppColors.kPrimaryContainer),
            SizedBox(height: 8),
            Text(
              'Mời qua email',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
