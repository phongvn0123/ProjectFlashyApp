import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/colors.dart';
import '../providers/classroom_providers.dart';
import '../tabs/classroom_activity_tab.dart';
import '../tabs/classroom_members_tab.dart';
import '../tabs/classroom_sets_tab.dart';

class ClassroomDetailPage extends ConsumerStatefulWidget {
  const ClassroomDetailPage({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<ClassroomDetailPage> createState() =>
      _ClassroomDetailPageState();
}

class _ClassroomDetailPageState extends ConsumerState<ClassroomDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref
        .watch(authControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final previewAsync = ref.watch(classroomDetailProvider(widget.classId));

    return previewAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      data: (preview) {
        if (preview == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Không tìm thấy lớp học')),
          );
        }

        final classroom = preview.classroom;
        final isTeacher =
            user != null &&
            (user.role == 'teacher' || user.role == 'admin') &&
            (classroom.teacherId == user.id || user.role == 'admin');

        return Scaffold(
          backgroundColor: AppColors.kBackground,
          appBar: AppBar(
            title: Text(classroom.name),
            actions: [
              if (isTeacher)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => _openSettings(context, classroom, user),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.kPrimaryContainer,
              unselectedLabelColor: AppColors.kOnSurfaceVariant,
              indicatorColor: AppColors.kPrimaryContainer,
              tabs: const [
                Tab(text: 'Hoạt động'),
                Tab(text: 'Bộ thẻ'),
                Tab(text: 'Thành viên'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ClassroomActivityTab(
                classId: widget.classId,
                isTeacher: isTeacher,
                header: ClassroomInfoHeader(
                  preview: preview,
                  isTeacher: isTeacher,
                  onShareCode: () {
                    Clipboard.setData(
                      ClipboardData(text: classroom.joinCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã lớp')),
                    );
                  },
                  onInviteStudents: () => _tabController.animateTo(2),
                ),
                onAssignSet: isTeacher
                    ? () => _tabController.animateTo(1)
                    : null,
              ),
              ClassroomSetsTab(
                classId: widget.classId,
                isTeacher: isTeacher,
                user: user,
                header: ClassroomInfoHeader(
                  preview: preview,
                  isTeacher: isTeacher,
                  onShareCode: () {
                    Clipboard.setData(
                      ClipboardData(text: classroom.joinCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã lớp')),
                    );
                  },
                  onInviteStudents: () => _tabController.animateTo(2),
                ),
              ),
              ClassroomMembersTab(
                classId: widget.classId,
                isTeacher: isTeacher,
                user: user,
                classroom: classroom,
                header: ClassroomInfoHeader(
                  preview: preview,
                  isTeacher: isTeacher,
                  onShareCode: () {
                    Clipboard.setData(
                      ClipboardData(text: classroom.joinCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã lớp')),
                    );
                  },
                  onInviteStudents: () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettings(
    BuildContext context,
    Classroom classroom,
    AppUser user,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Cập nhật thông tin lớp'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _editClass(context, classroom, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text('Sao chép mã: ${classroom.joinCode}'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: classroom.joinCode));
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã lớp')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Tạo mã tham gia mới'),
                subtitle: const Text('Hệ thống tự sinh mã mới'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final code = await ref
                      .read(repositoryProvider)
                      .regenerateJoinCode(classroom.id);
                  invalidateClassroomData(
                    ref,
                    classId: classroom.id,
                    userId: user.id,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mã mới: $code')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  classroom.isJoinEnabled ? Icons.lock_outline : Icons.lock_open,
                ),
                title: Text(
                  classroom.isJoinEnabled
                      ? 'Khóa mã tham gia'
                      : 'Mở mã tham gia',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await ref
                      .read(repositoryProvider)
                      .setJoinEnabled(classroom.id, !classroom.isJoinEnabled);
                  invalidateClassroomData(
                    ref,
                    classId: classroom.id,
                    userId: user.id,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xóa lớp học',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _confirmDelete(context, classroom, user);
                },
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editClass(
    BuildContext context,
    Classroom classroom,
    AppUser user,
  ) async {
    final result = await showDialog<({String name, String description})>(
      context: context,
      builder: (dialogContext) => _EditClassDialog(classroom: classroom),
    );
    if (result == null) return;
    await ref.read(repositoryProvider).updateClass(
      classId: classroom.id,
      name: result.name,
      description: result.description,
    );
    invalidateClassroomData(ref, classId: classroom.id, userId: user.id);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Classroom classroom,
    AppUser user,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa lớp học?'),
        content: Text(
          'Lớp "${classroom.name}" và dữ liệu liên quan sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).deleteClass(classroom.id);
    invalidateClassroomData(ref, userId: user.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _EditClassDialog extends StatefulWidget {
  const _EditClassDialog({required this.classroom});

  final Classroom classroom;

  @override
  State<_EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<_EditClassDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classroom.name);
    _descController = TextEditingController(text: widget.classroom.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cập nhật lớp học'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên lớp'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Mô tả'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, (
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
            ));
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class ClassroomInfoHeader extends StatelessWidget {
  const ClassroomInfoHeader({
    super.key,
    required this.preview,
    required this.isTeacher,
    required this.onShareCode,
    required this.onInviteStudents,
  });

  final ClassroomPreview preview;
  final bool isTeacher;
  final VoidCallback onShareCode;
  final VoidCallback onInviteStudents;

  @override
  Widget build(BuildContext context) {
    final classroom = preview.classroom;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kOutlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN LỚP HỌC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.kOutline,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.kPrimaryContainer.withValues(
                  alpha: 0.12,
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.kPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.description.isNotEmpty
                          ? classroom.description
                          : classroom.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        Text('Mã lớp: ${classroom.joinCode}'),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onShareCode,
                          icon: const Icon(Icons.copy, size: 18),
                        ),
                      ],
                    ),
                    Text(
                      '${preview.studentCount} học sinh • GV: ${preview.teacherName}',
                      style: const TextStyle(
                        color: AppColors.kOnSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isTeacher) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShareCode,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Chia sẻ mã'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onInviteStudents,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Mời học sinh'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
