import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

Activity _todo(
  String id,
  DateTime due, {
  ActivityState state = ActivityState.planned,
}) => Activity(
  id: id,
  type: ActivityType.todo,
  relatedType: RelatedType.opportunity,
  relatedId: 'o-$id',
  summary: id,
  ownerId: 'u',
  dueAt: due,
  state: state,
  updatedAt: due,
);

Opportunity _opp(String id, {String stage = 's-new'}) => Opportunity(
  id: id,
  title: id,
  customerId: 'c',
  stageId: stage,
  ownerId: 'u',
  teamId: 't',
  updatedAt: DateTime.utc(2026),
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('FR-MOB-002 groups in the user timezone', () {
    // 2026-10-12 20:00 UTC == 2026-10-13 01:45 Asia/Kathmandu (+05:45).
    final now = DateTime.utc(2026, 10, 12, 20);
    final s = MockDashboardRepository.computeSummary(
      activities: [
        _todo('overdue', now.subtract(const Duration(hours: 1))),
        // 22:00 UTC is still "today" in Kathmandu (03:45 next day local).
        _todo('today', DateTime.utc(2026, 10, 12, 22)),
        // 2026-10-13 18:15 UTC == 2026-10-14 00:00 Kathmandu -> tomorrow.
        _todo('upcoming', DateTime.utc(2026, 10, 13, 18, 15)),
        _todo('done', now, state: ActivityState.done),
      ],
      opportunities: [
        _opp('o-today'),
        _opp('o-none'),
        _opp('o-won', stage: 's-won'),
      ],
      followUpTypes: {ActivityType.todo},
      wonStageIds: {'s-won'},
      now: now,
      timezone: 'Asia/Kathmandu',
    );
    expect(s.overdue.map((a) => a.id), ['overdue']);
    expect(s.overdue.single.state, ActivityState.overdue);
    expect(s.today.map((a) => a.id), ['today']);
    expect(s.upcoming.map((a) => a.id), ['upcoming']);
    // Only open, non-won opportunities without an open follow-up.
    expect(s.noFollowUp.map((o) => o.id), ['o-none']);
  });

  test('unknown timezone falls back to UTC instead of crashing', () {
    final now = DateTime.utc(2026, 10, 12, 20);
    final s = MockDashboardRepository.computeSummary(
      activities: [_todo('a', DateTime.utc(2026, 10, 12, 23))],
      opportunities: const [],
      followUpTypes: {ActivityType.todo},
      wonStageIds: const {},
      now: now,
      timezone: 'Nowhere/Nope',
    );
    expect(s.today.length, 1);
  });
}
