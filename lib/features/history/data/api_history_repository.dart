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
        ? ApiConstant.customerHistoryUrl(id)
        : ApiConstant.crmLeadHistoryUrl(id);

    final res = await client.get<List<HistoryEntry>>(
      url,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseHistoryItem(Map<String, dynamic>.from(item)),
        ];
      },
    );

    return res.map((remoteEntries) {
      final sessionEntries = client.getSessionHistory(type, id);
      final byId = <String, HistoryEntry>{
        for (final e in sessionEntries) e.id: e,
        for (final e in remoteEntries) e.id: e,
      };
      return byId.values.toList()..sort((a, b) => b.at.compareTo(a.at));
    });
  }
}
