import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/history/domain/history_repository.dart';

class ApiHistoryRepository implements HistoryRepository {
  ApiHistoryRepository(this.client);

  final CrmApiClient client;

  @override
  Future<Result<List<HistoryEntry>, Failure>> forRecord(
    RelatedType type,
    String id,
  ) async {
    final url = type == RelatedType.customer
        ? ApiConstant.customerActivitiesUrl(id)
        : ApiConstant.crmLeadActivitiesUrl(id);

    final res = await client.get<List<HistoryEntry>>(
      url,
      params: {
        'include_done': true,
        if (type == RelatedType.customer) 'include_leads': true,
      },
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        final entries = <HistoryEntry>[];
        for (final item in list) {
          if (item is! Map) continue;
          final json = Map<String, dynamic>.from(item);
          final act = client.parseActivity(json);
          if (act.state != ActivityState.done) continue;

          String actorName = client.currentUser?.name ?? 'User';
          if (json['user'] is Map) {
            final u = json['user'] as Map;
            final n = u['name']?.toString().trim();
            if (n != null && n.isNotEmpty) actorName = n;
          }

          final outcomeText =
              (act.outcome != null &&
                  act.outcome!.isNotEmpty &&
                  act.outcome != act.summary)
              ? ' — ${act.outcome}'
              : '';

          entries.add(
            HistoryEntry(
              id: 'h-${act.id}',
              kind: act.type == ActivityType.note
                  ? HistoryKind.note
                  : HistoryKind.activity,
              at: act.dueAt ?? act.updatedAt,
              actorName: actorName,
              text: '${act.summary}$outcomeText',
            ),
          );
        }
        return entries;
      },
    );

    return res.map((remoteEntries) {
      final sessionEntries = client.getSessionHistory(type, id);
      final byId = <String, HistoryEntry>{
        for (final e in remoteEntries) e.id: e,
        for (final e in sessionEntries) e.id: e,
      };
      return byId.values.toList()..sort((a, b) => b.at.compareTo(a.at));
    });
  }
}

