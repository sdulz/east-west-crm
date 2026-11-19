import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/domain/activity_repository.dart';
import 'package:field_crm/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_repository.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_summary.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/opportunities/domain/opportunity_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository({
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
  Future<Result<DashboardSummary, Failure>> summary() async {
    final stagesFuture = pipelineRepository.stages();
    final oppsFuture = opportunityRepository.list();
    final actsFuture = activityRepository.list();

    final stagesRes = await stagesFuture;
    if (stagesRes case Err(:final error)) return Err(error);

    final oppsRes = await oppsFuture;
    if (oppsRes case Err(:final error)) return Err(error);

    final actsRes = await actsFuture;
    if (actsRes case Err(:final error)) return Err(error);

    final stages = (stagesRes as Ok<List<PipelineStage>, Failure>).value;
    final opps = (oppsRes as Ok<List<Opportunity>, Failure>).value;
    final acts = (actsRes as Ok<List<Activity>, Failure>).value;

    final me = client.currentUser;
    final myId = me?.id;
    final myName = me?.name.toLowerCase();

    bool isMine(String ownerId) {
      if (myId == null) return true;
      if (ownerId == myId) return true;
      final ownerName = client.usersById[ownerId]?.name.toLowerCase();
      if (myName != null && ownerName != null && ownerName == myName) {
        return true;
      }
      return false;
    }

    final myOpps = opps.where((o) => isMine(o.ownerId)).toList();
    final myActs = acts.where((a) => isMine(a.ownerId)).toList();

    final effectiveOpps = myOpps.isNotEmpty ? myOpps : opps;
    final effectiveActs = myActs.isNotEmpty ? myActs : acts;

    final wonStageIds = stages
        .where((s) => s.isWon || s.isFolded)
        .map((s) => s.id)
        .toSet();

    return Ok(
      MockDashboardRepository.computeSummary(
        activities: effectiveActs,
        opportunities: effectiveOpps,
        followUpTypes: const {
          ActivityType.todo,
          ActivityType.call,
          ActivityType.visit,
          ActivityType.meeting,
        },
        wonStageIds: wonStageIds,
        now: DateTime.now().toUtc(),
        timezone: me?.timezone ?? 'Asia/Kathmandu',
      ),
    );
  }
}

