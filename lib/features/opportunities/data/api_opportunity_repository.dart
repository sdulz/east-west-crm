import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/opportunities/domain/opportunity_repository.dart';

class ApiOpportunityRepository implements OpportunityRepository {
  ApiOpportunityRepository(this.client);

  final CrmApiClient client;

  static const Map<String, String> _leadFieldMap = {
    'name': 'title',
    'stage_id': 'stageId',
    'partner_id': 'customerId',
    'user_id': 'ownerId',
    'expected_revenue': 'expectedRevenue',
    'probability': 'probability',
    'date_deadline': 'nextActionAt',
    'description': 'nextActionSummary',
  };

  @override
  Future<Result<List<Opportunity>, Failure>> list({String? customerId}) async {
    final partnerId = customerId != null ? int.tryParse(customerId) : null;
    final res = await client.get<List<Opportunity>>(
      ApiConstant.crmLeadsUrl,
      params: {
        'page': 1,
        'limit': 100,
        if (partnerId != null) 'partner_id': partnerId,
      },
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseLead(Map<String, dynamic>.from(item)),
        ];
      },
    );
    return res.map((items) {
      final filtered = (customerId != null && partnerId == null)
          ? items.where((o) => o.customerId == customerId).toList()
          : [...items];
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return filtered;
    });
  }

  @override
  Future<Result<Opportunity, Failure>> getById(String id) {
    return client.get<Opportunity>(
      ApiConstant.crmLeadByIdUrl(id),
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return client.parseLead(data);
      },
    );
  }

  @override
  Future<Result<Opportunity, Failure>> create(Opportunity o) async {
    final title = o.title.trim();
    if (title.isEmpty) {
      return const Err(
        Failure.validation('Title is required', field: 'title'),
      );
    }
    final stageId = int.tryParse(o.stageId);
    final partnerId = int.tryParse(o.customerId);
    final summary = o.nextActionSummary?.trim();

    final body = <String, dynamic>{
      'name': title,
      if (stageId != null && stageId > 0) 'stage_id': stageId,
      if (partnerId != null && partnerId > 0) 'partner_id': partnerId,
      'expected_revenue': o.expectedRevenue,
      'probability': o.probability.toDouble(),
      if (o.nextActionAt != null)
        'date_deadline': CrmApiClient.formatDate(o.nextActionAt!),
      if (summary != null && summary.isNotEmpty) 'description': summary,
    };

    return client.post<Opportunity>(
      ApiConstant.crmLeadsUrl,
      body: body,
      fieldMap: _leadFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return client.parseLead(data);
      },
    );
  }

  @override
  Future<Result<Opportunity, Failure>> update(
    Opportunity o, {
    required DateTime expectedUpdatedAt,
  }) async {
    final title = o.title.trim();
    if (title.isEmpty) {
      return const Err(
        Failure.validation('Title is required', field: 'title'),
      );
    }
    final stageId = int.tryParse(o.stageId);
    final partnerId = int.tryParse(o.customerId);
    final summary = o.nextActionSummary?.trim();

    final body = <String, dynamic>{
      'name': title,
      if (stageId != null && stageId > 0) 'stage_id': stageId,
      'partner_id': (partnerId != null && partnerId > 0) ? partnerId : null,
      'expected_revenue': o.expectedRevenue,
      'probability': o.probability.toDouble(),
      'date_deadline': o.nextActionAt != null
          ? CrmApiClient.formatDate(o.nextActionAt!)
          : null,
      'description': (summary == null || summary.isEmpty) ? null : summary,
    };

    return client.put<Opportunity>(
      ApiConstant.crmLeadByIdUrl(o.id),
      body: body,
      fieldMap: _leadFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return client.parseLead(data);
      },
    );
  }

  @override
  Future<Result<Opportunity, Failure>> changeStage(
    String id, {
    required String toStageId,
    required DateTime expectedUpdatedAt,
  }) async {
    final stageIdInt = int.tryParse(toStageId);
    if (stageIdInt == null || stageIdInt <= 0) {
      return Err(
        Failure.validation('Unknown stage $toStageId', field: 'stageId'),
      );
    }

    String? toStageName;
    final res = await client.put<Opportunity>(
      ApiConstant.crmLeadStageUrl(id),
      body: {'stage_id': stageIdInt},
      fieldMap: _leadFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        if (data['stage'] is Map) {
          toStageName = (data['stage'] as Map)['name']?.toString();
        }
        return client.parseLead(data);
      },
    );

    if (res case Ok(:final value)) {
      client.addSessionHistory(
        RelatedType.opportunity,
        id,
        HistoryEntry(
          id: 'h-stage-${DateTime.now().microsecondsSinceEpoch}',
          kind: HistoryKind.stageChange,
          at: DateTime.now().toUtc(),
          actorName: client.currentUser?.name ?? 'User',
          from: null,
          to: toStageName ?? value.stageId,
        ),
      );
    }

    return res;
  }

  @override
  Future<Result<Opportunity, Failure>> reassign(
    String id, {
    required String newOwnerId,
    required DateTime expectedUpdatedAt,
  }) async {
    final userIdInt = int.tryParse(newOwnerId);
    if (userIdInt == null || userIdInt <= 0) {
      return const Err(
        Failure.validation(
          'Owner must be an active member of your team',
          field: 'ownerId',
        ),
      );
    }

    String? newOwnerName;
    final res = await client.put<Opportunity>(
      ApiConstant.crmLeadByIdUrl(id),
      body: {'user_id': userIdInt},
      fieldMap: _leadFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        if (data['user'] is Map) {
          newOwnerName = (data['user'] as Map)['name']?.toString();
        }
        return client.parseLead(data);
      },
    );

    if (res case Ok(:final value)) {
      client.addSessionHistory(
        RelatedType.opportunity,
        id,
        HistoryEntry(
          id: 'h-owner-${DateTime.now().microsecondsSinceEpoch}',
          kind: HistoryKind.ownerChange,
          at: DateTime.now().toUtc(),
          actorName: client.currentUser?.name ?? 'User',
          from: null,
          to:
              newOwnerName ??
              client.usersById[value.ownerId]?.name ??
              value.ownerId,
        ),
      );
    }

    return res;
  }
}

