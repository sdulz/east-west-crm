import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/handover/domain/user_directory_repository.dart';

class MockUserDirectoryRepository implements UserDirectoryRepository {
  MockUserDirectoryRepository(this.store);
  final MockStore store;

  @override
  Future<Result<List<AppUser>, Failure>> users() => store.call(() {
    final me = store.currentUser;
    return store.state.users.where((u) => u.teamId == me.teamId).toList();
  });

  @override
  Future<Result<List<AppUser>, Failure>> assignableUsers() => store.call(() {
    final me = store.currentUser;
    if (!me.permissions.canReassign) {
      throw const MockFailure(Failure.permissionDenied());
    }
    return store.state.users
        .where((u) => u.teamId == me.teamId && u.isActive)
        .toList();
  });
}
