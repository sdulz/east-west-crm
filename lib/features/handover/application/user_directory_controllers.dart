import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';

final visibleUsersProvider = FutureProvider<List<AppUser>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(userDirectoryRepositoryProvider).users().orThrow;
});

final userNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final users = await ref.watch(visibleUsersProvider.future);
  return {for (final u in users) u.id: u.name};
});

final assignableUsersProvider = FutureProvider<List<AppUser>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(userDirectoryRepositoryProvider).assignableUsers().orThrow;
});
