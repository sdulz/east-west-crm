import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_directory_controllers.g.dart';

@riverpod
Future<List<AppUser>> visibleUsers(Ref ref) {
  ref.watch(currentUserProvider);
  return ref.watch(userDirectoryRepositoryProvider).users().orThrow;
}

@riverpod
Future<Map<String, String>> userNames(Ref ref) async {
  final users = await ref.watch(visibleUsersProvider.future);
  return {for (final u in users) u.id: u.name};
}

/// FR-MOB-009 candidates. Permission-denied when the user cannot reassign.
@riverpod
Future<List<AppUser>> assignableUsers(Ref ref) {
  ref.watch(currentUserProvider);
  return ref.watch(userDirectoryRepositoryProvider).assignableUsers().orThrow;
}
