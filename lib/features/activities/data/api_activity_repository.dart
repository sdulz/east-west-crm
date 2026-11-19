import 'dart:io';

import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/domain/activity_repository.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';

class ApiActivityRepository implements ActivityRepository {
  ApiActivityRepository(this.client);

  final CrmApiClient client;

  static const Map<String, String> _activityFieldMap = {
    'activity_type_id': 'type',
    'summary': 'summary',
    'note': 'outcome',
    'date_deadline': 'dueAt',
    'user_id': 'ownerId',
    'feedback': 'outcome',
    'body': 'summary',
  };

  @override
  Future<Result<List<ActivityTypeDef>, Failure>> types() async {
    final res = await client.get<List<OdooActivityType>>(
      ApiConstant.activityTypesUrl,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              OdooActivityType.fromJson(Map<String, dynamic>.from(item)),
        ]..sort((a, b) => a.sequence.compareTo(b.sequence));
      },
    );

    if (res case Err(:final error)) {
      return Err(error);
    }

    final odooTypes = (res as Ok<List<OdooActivityType>, Failure>).value;
    client.odooActivityTypes = odooTypes;

    String labelFor(ActivityType domainType, String fallback) {
      for (final t in odooTypes) {
        if (t.toDomainType() == domainType && t.name.trim().isNotEmpty) {
          return t.name.trim();
        }
      }
      return fallback;
    }

    return Ok([
      ActivityTypeDef(
        type: ActivityType.call,
        label: labelFor(ActivityType.call, 'Call'),
      ),
      ActivityTypeDef(
        type: ActivityType.visit,
        label: labelFor(ActivityType.visit, 'Visit'),
      ),
      ActivityTypeDef(
        type: ActivityType.meeting,
        label: labelFor(ActivityType.meeting, 'Meeting'),
      ),
      const ActivityTypeDef(
        type: ActivityType.note,
        label: 'Note',
      ),
      ActivityTypeDef(
        type: ActivityType.todo,
        label: labelFor(ActivityType.todo, 'Follow-up'),
        isFollowUp: true,
      ),
    ]);
  }

  @override
  Future<Result<List<Activity>, Failure>> list([ActivityFilter? filter]) async {
    final f = filter ?? const ActivityFilter();
    final now = DateTime.now().toUtc();

    Result<List<Activity>, Failure> rawResult;
    if (f.relatedType == RelatedType.opportunity && f.relatedId != null) {
      rawResult = await _fetchLeadActivities(f.relatedId!);
    } else if (f.relatedType == RelatedType.customer && f.relatedId != null) {
      rawResult = await _fetchCustomerActivities(
        f.relatedId!,
        includeLeads: false,
      );
    } else {
      rawResult = await _fetchAllVisibleActivities();
    }

    return rawResult.map((items) {
      return items
          .map((a) => _withDerivedState(a, now))
          .where((a) => f.relatedType == null || a.relatedType == f.relatedType)
          .where((a) => f.relatedId == null || a.relatedId == f.relatedId)
          .where((a) => f.ownerId == null || a.ownerId == f.ownerId)
          .where((a) => f.state == null || a.state == f.state)
          .where((a) => f.followUpsOnly != true || a.type != ActivityType.note)
          .where(
            (a) => f.dueFrom == null || (a.dueAt?.isAfter(f.dueFrom!) ?? false),
          )
          .where(
            (a) => f.dueTo == null || (a.dueAt?.isBefore(f.dueTo!) ?? false),
          )
          .toList()
        ..sort(
          (a, b) => (a.dueAt ?? a.updatedAt).compareTo(b.dueAt ?? b.updatedAt),
        );
    });
  }

  Future<Result<List<Activity>, Failure>> _fetchLeadActivities(
    String leadId,
  ) async {
    final res = await client.get<List<Activity>>(
      ApiConstant.crmLeadActivitiesUrl(leadId),
      params: const {'include_done': true},
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseActivity(Map<String, dynamic>.from(item)),
        ];
      },
    );
    return res.map((activities) {
      final notes = client.leadNotesById[leadId] ?? const <Activity>[];
      final byId = <String, Activity>{
        for (final a in activities) a.id: a,
        for (final n in notes) n.id: n,
      };
      return byId.values.toList();
    });
  }

  Future<Result<List<Activity>, Failure>> _fetchCustomerActivities(
    String customerId, {
    required bool includeLeads,
  }) async {
    final res = await client.get<List<Activity>>(
      ApiConstant.customerActivitiesUrl(customerId),
      params: {
        'include_done': true,
        'include_leads': includeLeads,
      },
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseActivity(Map<String, dynamic>.from(item)),
        ];
      },
    );
    return res.map((activities) {
      final notes =
          client.leadNotesById['customer:$customerId'] ?? const <Activity>[];
      final byId = <String, Activity>{
        for (final a in activities) a.id: a,
        for (final n in notes) n.id: n,
      };
      return byId.values.toList();
    });
  }

  Future<Result<List<Activity>, Failure>> _fetchAllVisibleActivities() async {
    final leadsRes = await client.get<List<String>>(
      ApiConstant.crmLeadsUrl,
      params: const {'page': 1, 'limit': 50},
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        final ids = <String>[];
        for (final item in list) {
          if (item is Map) {
            final lead = client.parseLead(Map<String, dynamic>.from(item));
            ids.add(lead.id);
          }
        }
        return ids;
      },
    );
    if (leadsRes case Err(:final error)) return Err(error);

    final customersRes = await client.get<List<String>>(
      ApiConstant.customersUrl,
      params: const {'page': 1, 'limit': 25},
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map && item['id'] != null) item['id'].toString(),
        ];
      },
    );

    final leadIds = (leadsRes as Ok<List<String>, Failure>).value;
    final customerIds = switch (customersRes) {
      Ok(:final value) => value,
      Err() => const <String>[],
    };

    final byId = <String, Activity>{};

    final futures = <Future<Result<List<Activity>, Failure>>>[
      for (final leadId in leadIds) _fetchLeadActivities(leadId),
      for (final customerId in customerIds)
        _fetchCustomerActivities(customerId, includeLeads: true),
    ];

    final results = await Future.wait(futures);
    for (final r in results) {
      if (r case Ok(:final value)) {
        for (final a in value) {
          byId[a.id] = a;
        }
      }
    }

    for (final notes in client.leadNotesById.values) {
      for (final n in notes) {
        byId[n.id] = n;
      }
    }

    return Ok(byId.values.toList());
  }

  @override
  Future<Result<Activity, Failure>> getById(String id) async {
    final cached = client.activitiesById[id];
    if (cached != null) {
      return Ok(_withDerivedState(cached, DateTime.now().toUtc()));
    }
    final all = await list();
    return switch (all) {
      Ok(:final value) => switch (value.where((a) => a.id == id).firstOrNull) {
        final hit? => Ok(hit),
        null => const Err(Failure.unknown('Not found')),
      },
      Err(:final error) => Err(error),
    };
  }

  @override
  Future<Result<Activity, Failure>> create(Activity a) async {
    final summary = a.summary.trim();
    if (summary.isEmpty) {
      return const Err(
        Failure.validation('Summary is required', field: 'summary'),
      );
    }

    // 1. Notes on leads/opportunities use `POST /api/v1/crm/leads/{lead_id}/notes`.
    if (a.type == ActivityType.note &&
        a.relatedType == RelatedType.opportunity) {
      final validFiles = <File>[];
      for (final path in a.attachments) {
        if (!path.startsWith('http://') && !path.startsWith('https://')) {
          final file = File(path);
          if (file.existsSync()) validFiles.add(file);
        }
      }
      final useMultipart = validFiles.isNotEmpty;
      final Object body = useMultipart
          ? <String, dynamic>{
              'body': summary,
              'files': validFiles,
            }
          : <String, dynamic>{'body': summary};

      return client.post<Activity>(
        ApiConstant.crmLeadNotesUrl(a.relatedId),
        body: body,
        isMultipart: useMultipart,
        fieldMap: _activityFieldMap,
        parse: (raw) {
          final map = Map<String, dynamic>.from(raw as Map);
          final data = Map<String, dynamic>.from(map['data'] as Map);
          return client.parseNote(data, leadId: a.relatedId);
        },
      );
    }

    // 2. Notes on customers: store in session notes & post a done activity if possible.
    if (a.type == ActivityType.note && a.relatedType == RelatedType.customer) {
      final noteActivity = a.copyWith(
        state: ActivityState.done,
        updatedAt: DateTime.now().toUtc(),
      );
      final list = client.leadNotesById.putIfAbsent(
        'customer:${a.relatedId}',
        () => [],
      );
      list.removeWhere((x) => x.id == noteActivity.id);
      list.add(noteActivity);
      client.addSessionHistory(
        RelatedType.customer,
        a.relatedId,
        HistoryEntry(
          id: 'h-${noteActivity.id}',
          kind: HistoryKind.note,
          at: noteActivity.updatedAt,
          actorName: client.currentUser?.name ?? 'User',
          text: summary,
        ),
      );
      return Ok(noteActivity);
    }

    // 3. Scheduled activities and logged interactions on leads or customers.
    if (a.type == ActivityType.todo && a.dueAt == null) {
      return const Err(
        Failure.validation(
          'Follow-ups need a due date and time',
          field: 'dueAt',
        ),
      );
    }

    final typeId = await _resolveOdooActivityTypeId(
      a.type,
      a.relatedType,
    );
    if (typeId == null) {
      return const Err(
        Failure.validation('No matching activity type configured', field: 'type'),
      );
    }

    final url = a.relatedType == RelatedType.customer
        ? ApiConstant.customerActivitiesUrl(a.relatedId)
        : ApiConstant.crmLeadActivitiesUrl(a.relatedId);

    final userId = int.tryParse(a.ownerId);
    final body = <String, dynamic>{
      'activity_type_id': typeId,
      'summary': summary,
      if (a.outcome != null && a.outcome!.trim().isNotEmpty)
        'note': a.outcome!.trim(),
      if (a.dueAt != null) 'date_deadline': CrmApiClient.formatDate(a.dueAt!),
      if (userId != null && userId > 0) 'user_id': userId,
    };

    final createdRes = await client.post<Activity>(
      url,
      body: body,
      fieldMap: _activityFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return client.parseActivity(data);
      },
    );

    if (createdRes case Err(:final error)) {
      return Err(error);
    }

    final created = (createdRes as Ok<Activity, Failure>).value;

    // If this is a logged interaction (Call, Visit, Meeting) rather than a
    // scheduled follow-up (`todo`), mark it done in Odoo immediately if an
    // outcome was provided.
    if (a.type != ActivityType.todo &&
        a.outcome != null &&
        a.outcome!.trim().isNotEmpty &&
        int.tryParse(created.id) != null) {
      final doneRes = await complete(
        created.id,
        outcome: a.outcome!.trim(),
        expectedUpdatedAt: created.updatedAt,
      );
      if (doneRes case Ok(:final value)) {
        return Ok(value.copyWith(type: a.type));
      }
    }

    return Ok(created.copyWith(type: a.type));
  }

  @override
  Future<Result<Activity, Failure>> complete(
    String id, {
    required String outcome,
    required DateTime expectedUpdatedAt,
  }) async {
    final trimmed = outcome.trim();
    if (trimmed.isEmpty) {
      return const Err(
        Failure.validation('Outcome is required', field: 'outcome'),
      );
    }

    final res = await client.post<Activity>(
      ApiConstant.activityDoneUrl(id),
      body: {'feedback': trimmed},
      fieldMap: _activityFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return client.parseActivity(data);
      },
    );

    if (res case Ok(:final value)) {
      client.activitiesById.remove(id);
      client.addSessionHistory(
        value.relatedType,
        value.relatedId,
        HistoryEntry(
          id: 'h-${value.id}-done',
          kind: HistoryKind.activity,
          at: DateTime.now().toUtc(),
          actorName: client.currentUser?.name ?? 'User',
          text: '${value.summary} — $trimmed',
        ),
      );
    }

    return res;
  }

  @override
  Future<Result<Activity, Failure>> reschedule(
    String id, {
    required DateTime dueAt,
    required DateTime expectedUpdatedAt,
  }) async {
    final existing = client.activitiesById[id];
    if (existing == null) {
      return const Err(Failure.unknown('Activity not found'));
    }

    final typeId =
        client.activityTypeIdByActivityId[id] ??
        await _resolveOdooActivityTypeId(existing.type, existing.relatedType);
    if (typeId == null) {
      return const Err(
        Failure.validation('No matching activity type configured', field: 'type'),
      );
    }

    final url = existing.relatedType == RelatedType.customer
        ? ApiConstant.customerActivitiesUrl(existing.relatedId)
        : ApiConstant.crmLeadActivitiesUrl(existing.relatedId);

    final userId = int.tryParse(existing.ownerId);
    final createRes = await client.post<Activity>(
      url,
      body: {
        'activity_type_id': typeId,
        'summary': existing.summary,
        if (existing.outcome != null && existing.outcome!.isNotEmpty)
          'note': existing.outcome,
        'date_deadline': CrmApiClient.formatDate(dueAt),
        if (userId != null && userId > 0) 'user_id': userId,
      },
      fieldMap: _activityFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return client.parseActivity(data);
      },
    );

    if (createRes case Ok(:final value)) {
      if (int.tryParse(id) != null && id != value.id) {
        // Complete the superseded activity so only the rescheduled one stays open.
        await client.post<void>(
          ApiConstant.activityDoneUrl(id),
          body: {
            'feedback': 'Rescheduled to ${CrmApiClient.formatDate(dueAt)}',
          },
          parse: (_) {},
        );
        client.activitiesById.remove(id);
      }
    }

    return createRes;
  }

  Future<int?> _resolveOdooActivityTypeId(
    ActivityType domainType,
    RelatedType relatedType,
  ) async {
    if (client.odooActivityTypes.isEmpty) {
      await types();
    }
    final candidates = client.odooActivityTypes.where((t) {
      return relatedType == RelatedType.customer
          ? t.isUsableForCustomer
          : t.isUsableForLead;
    }).toList();

    for (final c in candidates) {
      if (c.toDomainType() == domainType) return c.id;
    }
    if (candidates.isNotEmpty) return candidates.first.id;
    if (client.odooActivityTypes.isNotEmpty) {
      return client.odooActivityTypes.first.id;
    }
    return 1;
  }

  Activity _withDerivedState(Activity a, DateTime now) {
    if (a.state == ActivityState.done) return a;
    final due = a.dueAt;
    if (due != null && due.isBefore(now)) {
      return a.copyWith(state: ActivityState.overdue);
    }
    return a.copyWith(state: ActivityState.planned);
  }
}
