import 'dart:convert';

import 'package:field_crm/core/mock/mock_state.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:field_crm/features/team/domain/team.dart';

/// Turns `assets/seed/seed.json` into a [MockState]. The seed uses day offsets
/// relative to "now" so Today / Overdue always have data, whenever it is run.
class MockSeedLoader {
  const MockSeedLoader();

  MockState fromJsonString(String json, {required DateTime now}) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    DateTime at(int days, [int hour = 9]) {
      final d = now.add(Duration(days: days));
      return DateTime.utc(d.year, d.month, d.day, hour);
    }

    final users = <AppUser>[];
    final passwords = <String, String>{};
    for (final u in j['users'] as List) {
      final m = Map<String, dynamic>.from(u as Map);
      passwords[m['email'] as String] = m.remove('password') as String;
      users.add(AppUser.fromJson(m));
    }

    final customers = (j['customers'] as List).map((c) {
      final m = Map<String, dynamic>.from(c as Map);
      m['updatedAt'] = at(m.remove('updatedAtOffsetDays') as int)
          .toIso8601String();
      return Customer.fromJson(m);
    }).toList();

    final opportunities = (j['opportunities'] as List).map((o) {
      final m = Map<String, dynamic>.from(o as Map);
      final next = m.remove('nextActionOffsetDays') as int?;
      m['nextActionAt'] = next == null ? null : at(next, 14).toIso8601String();
      m['updatedAt'] = at(m.remove('updatedAtOffsetDays') as int)
          .toIso8601String();
      return Opportunity.fromJson(m);
    }).toList();

    final activities = (j['activities'] as List).map((a) {
      final m = Map<String, dynamic>.from(a as Map);
      final due = at(
        m.remove('dueOffsetDays') as int,
        m.remove('dueHour') as int,
      );
      m['dueAt'] = due.toIso8601String();
      m['updatedAt'] = at(m.remove('updatedAtOffsetDays') as int)
          .toIso8601String();
      return Activity.fromJson(m);
    }).toList();

    final nameOf = {for (final u in users) u.id: u.name};
    final history = <String, List<HistoryEntry>>{};
    for (final a in activities.where((a) => a.state == ActivityState.done)) {
      history
          .putIfAbsent(
            MockState.historyKey(a.relatedType, a.relatedId),
            () => [],
          )
          .add(
            HistoryEntry(
              id: 'h-${a.id}',
              kind: a.type == ActivityType.note
                  ? HistoryKind.note
                  : HistoryKind.activity,
              at: a.dueAt ?? a.updatedAt,
              actorName: nameOf[a.ownerId] ?? a.ownerId,
              text: '${a.summary}${a.outcome == null ? '' : ' — ${a.outcome}'}',
            ),
          );
    }

    return MockState(
      users: users,
      passwords: passwords,
      teams: MockState.listFromJson(j['teams'], Team.fromJson),
      stages: MockState.listFromJson(j['stages'], PipelineStage.fromJson),
      products: MockState.listFromJson(j['products'], Product.fromJson),
      activityTypes: MockState.listFromJson(
        j['activityTypes'],
        ActivityTypeDef.fromJson,
      ),
      customers: customers,
      opportunities: opportunities,
      activities: activities,
      history: history,
    );
  }
}
