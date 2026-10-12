import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/team/domain/team.dart';
import 'package:field_crm/features/team/domain/team_repository.dart';

class MockTeamRepository implements TeamRepository {
  MockTeamRepository(this.store);
  final MockStore store;

  @override
  Future<Result<TeamOverview, Failure>> overview() => store.call(() {
    final me = store.currentUser;
    if (!me.permissions.canViewTeam) {
      throw const MockFailure(Failure.permissionDenied());
    }
    final team = store.state.teams.firstWhere((t) => t.id == me.teamId);
    final closed = store.state.stages
        .where((s) => s.isWon || s.isFolded)
        .map((s) => s.id)
        .toSet();
    final now = store.clock.now();
    final members = store.state.users
        .where(
          (u) =>
              u.teamId == team.id &&
              u.role == UserRole.salesperson &&
              u.isActive,
        )
        .map(
          (u) => TeamMemberOverview(
            user: u,
            openOpportunities: store.state.opportunities
                .where((o) => o.ownerId == u.id && !closed.contains(o.stageId))
                .toList(),
            overdueActivities: store.state.activities
                .where(
                  (a) =>
                      a.ownerId == u.id &&
                      a.state != ActivityState.done &&
                      (a.dueAt?.isBefore(now) ?? false),
                )
                .map((a) => a.copyWith(state: ActivityState.overdue))
                .toList(),
          ),
        )
        .toList();
    return TeamOverview(team: team, members: members);
  });
}
