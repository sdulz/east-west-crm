import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/domain/activity_repository.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/opportunities/domain/opportunity_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:field_crm/features/team/domain/team.dart';
import 'package:field_crm/features/team/domain/team_repository.dart';

class ApiTeamRepository implements TeamRepository {
  ApiTeamRepository({
    required this.client,
    required this.opportunityRepository,
    required this.activityRepository,
    required this.pipelineRepository,
  });

  final CrmApiClient client;
  final OpportunityRepository opportunityRepository;
  final ActivityRepository activityRepository;
  final PipelineRepository pipelineRepository;

  @override
  Future<Result<TeamOverview, Failure>> overview() async {
    final me = client.currentUser;
    if (me != null && !me.permissions.canViewTeam) {
      return const Err(Failure.permissionDenied());
    }

    final stagesRes = await pipelineRepository.stages();
    if (stagesRes case Err(:final error)) return Err(error);

    final oppsRes = await opportunityRepository.list();
    if (oppsRes case Err(:final error)) return Err(error);

    final actsRes = await activityRepository.list();
    if (actsRes case Err(:final error)) return Err(error);

    final stages = (stagesRes as Ok<List<PipelineStage>, Failure>).value;
    final opps = (oppsRes as Ok<List<Opportunity>, Failure>).value;
    final acts = (actsRes as Ok<List<Activity>, Failure>).value;

    final closedStageIds = stages
        .where((s) => s.isWon || s.isFolded)
        .map((s) => s.id)
        .toSet();
    final now = DateTime.now().toUtc();

    final membersById = <String, AppUser>{...client.usersById};
    if (me != null) {
      membersById.putIfAbsent(me.id, () => me);
    }

    final team = client.teamsById.values.firstOrNull ??
        Team(
          id: me?.teamId ?? '1',
          name: 'Sales Team',
          supervisorId: me?.id ?? '1',
        );

    final members = membersById.values
        .where((u) => u.isActive)
        .map(
          (u) => TeamMemberOverview(
            user: u,
            openOpportunities: opps
                .where(
                  (o) =>
                      o.ownerId == u.id && !closedStageIds.contains(o.stageId),
                )
                .toList(),
            overdueActivities: acts
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

    return Ok(
      TeamOverview(
        team: team,
        members: members,
      ),
    );
  }
}
