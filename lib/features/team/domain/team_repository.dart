import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/team/domain/team.dart';

abstract interface class TeamRepository {
  /// Requires `permissions.canViewTeam`; otherwise `Failure.permissionDenied`.
  Future<Result<TeamOverview, Failure>> overview();
}
