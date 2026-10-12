import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';

abstract interface class UserDirectoryRepository {
  /// Users the current user may see (for names in lists).
  Future<Result<List<AppUser>, Failure>> users();

  /// Users the current user may reassign records to.
  Future<Result<List<AppUser>, Failure>> assignableUsers();
}
