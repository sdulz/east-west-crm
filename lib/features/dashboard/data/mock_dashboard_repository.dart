import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_repository.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_summary.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';

class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository(this.store);
  final MockStore store;

  @override
  Future<Result<DashboardSummary, Failure>> summary() => store.call(() {
    final me = store.currentUser;
    final now = store.clock.now();
    return computeSummary(
      activities: store.visibleActivities().where((a) => a.ownerId == me.id),
      opportunities: store.visibleOpportunities().where(
        (o) => o.ownerId == me.id,
      ),
      followUpTypes: store.state.activityTypes
          .where((t) => t.isFollowUp)
          .map((t) => t.type)
          .toSet(),
      wonStageIds: store.state.stages
          .where((s) => s.isWon || s.isFolded)
          .map((s) => s.id)
          .toSet(),
      now: now,
      timezone: me.timezone,
    );
  });

  /// Pure grouping logic (FR-MOB-002), exposed for unit tests.
  static DashboardSummary computeSummary({
    required Iterable<Activity> activities,
    required Iterable<Opportunity> opportunities,
    required Set<ActivityType> followUpTypes,
    required Set<String> wonStageIds,
    required DateTime now,
    required String timezone,
  }) {
    final dayStart = startOfDay(now, timezone);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final open =
        activities
            .where((a) => a.state != ActivityState.done)
            .where((a) => followUpTypes.contains(a.type) && a.dueAt != null)
            .toList()
          ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final today = <Activity>[];
    final upcoming = <Activity>[];
    final overdue = <Activity>[];
    for (final a in open) {
      final due = a.dueAt!;
      if (due.isBefore(now)) {
        overdue.add(a.copyWith(state: ActivityState.overdue));
      } else if (due.isBefore(dayEnd)) {
        today.add(a);
      } else {
        upcoming.add(a);
      }
    }
    final withFollowUp = open.map((a) => a.relatedId).toSet();
    final noFollowUp =
        opportunities
            .where((o) => !wonStageIds.contains(o.stageId))
            .where((o) => !withFollowUp.contains(o.id))
            .toList()
          ..sort((a, b) => a.title.compareTo(b.title));
    return DashboardSummary(
      today: today,
      upcoming: upcoming,
      overdue: overdue,
      noFollowUp: noFollowUp,
    );
  }
}
