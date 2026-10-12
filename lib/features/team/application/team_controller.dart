import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/team/domain/team.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'team_controller.g.dart';

/// FR-MOB-014.
@riverpod
Future<TeamOverview> teamOverview(Ref ref) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(teamRepositoryProvider).overview().orThrow;
}
