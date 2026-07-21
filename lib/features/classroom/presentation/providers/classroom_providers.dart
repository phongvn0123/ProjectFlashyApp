import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/memocard_models.dart';
import '../../../../core/providers/app_providers.dart';

final classroomDetailProvider = FutureProvider.autoDispose
    .family<ClassroomPreview?, String>((ref, classId) {
      final repo = ref.watch(repositoryProvider);
      return repo.ensureSeedData().then((_) => repo.classroomPreview(classId));
    });

final classMembersProvider = FutureProvider.autoDispose
    .family<List<ClassMember>, String>((ref, classId) {
      return ref.watch(repositoryProvider).membersOf(classId);
    });

final assignedSetsProvider = FutureProvider.autoDispose
    .family<List<AssignedSetItem>, String>((ref, classId) {
      return ref.watch(repositoryProvider).assignedSetsForClass(classId);
    });

final classActivitiesProvider = FutureProvider.autoDispose
    .family<List<ClassActivity>, String>((ref, classId) {
      return ref.watch(repositoryProvider).activitiesForClass(classId);
    });

final classCompletionRateProvider = FutureProvider.autoDispose
    .family<double, String>((ref, classId) {
      return ref.watch(repositoryProvider).classCompletionRate(classId);
    });

void invalidateClassroomData(WidgetRef ref, {String? classId, String? userId}) {
  if (userId != null) {
    ref.invalidate(classroomProvider(userId));
  }
  if (classId != null) {
    ref.invalidate(classroomDetailProvider(classId));
    ref.invalidate(classMembersProvider(classId));
    ref.invalidate(assignedSetsProvider(classId));
    ref.invalidate(classActivitiesProvider(classId));
    ref.invalidate(classCompletionRateProvider(classId));
  }
}
