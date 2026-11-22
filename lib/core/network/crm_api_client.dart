import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';
import 'package:field_crm/common/utils/base_repo_provider.dart';
import 'package:field_crm/common/utils/base_repository/base_repository.dart';
import 'package:field_crm/common/utils/base_repository/custom_api_exception.dart';
import 'package:field_crm/common/utils/base_repository/model/request_input.dart';
import 'package:field_crm/common/utils/base_repository/repository_details.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:field_crm/features/team/domain/team.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Raw activity type metadata returned by `GET /api/v1/activity-types`.
class OdooActivityType {
  const OdooActivityType({
    required this.id,
    required this.name,
    required this.category,
    required this.sequence,
    this.icon,
    this.model,
    this.summary,
    this.defaultNote,
    this.delayCount = 0,
    this.delayUnit = 'days',
    this.defaultDeadline,
  });

  final int id;
  final String name;
  final String category;
  final int sequence;
  final String? icon;
  final String? model; // 'lead', 'customer', or null (both)
  final String? summary;
  final String? defaultNote;
  final int delayCount;
  final String delayUnit;
  final String? defaultDeadline;

  factory OdooActivityType.fromJson(Map<String, dynamic> json) {
    return OdooActivityType(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'default').toString(),
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      icon: json['icon'] as String?,
      model: json['model'] as String?,
      summary: json['summary'] as String?,
      defaultNote: json['default_note'] as String?,
      delayCount: (json['delay_count'] as num?)?.toInt() ?? 0,
      delayUnit: (json['delay_unit'] ?? 'days').toString(),
      defaultDeadline: json['default_deadline'] as String?,
    );
  }

  ActivityType toDomainType() {
    final lowerName = name.toLowerCase();
    final lowerCat = category.toLowerCase();
    if (lowerCat == 'phonecall' || lowerName.contains('call')) {
      return ActivityType.call;
    }
    if (lowerCat == 'meeting' || lowerName.contains('meeting')) {
      return ActivityType.meeting;
    }
    if (lowerName.contains('visit') || lowerName.contains('site')) {
      return ActivityType.visit;
    }
    return ActivityType.todo;
  }

  bool get isUsableForLead => model == null || model == 'lead';
  bool get isUsableForCustomer => model == null || model == 'customer';
}

/// Central HTTP client and entity metadata cache for the East West CRM API.
class CrmApiClient {
  CrmApiClient(this.ref);

  final Ref ref;

  static String? _activeToken;
  static String? get activeToken => _activeToken;
  static void setActiveToken(String? token) {
    _activeToken = token;
  }

  AppUser? currentUser;

  /// Discovered users (`id -> AppUser`) from profile, leads, and activities.
  final Map<String, AppUser> usersById = {};

  /// Discovered sales teams (`id -> Team`) from stages and leads.
  final Map<String, Team> teamsById = {};

  /// Cached Odoo activity types from `GET /api/v1/activity-types`.
  List<OdooActivityType> odooActivityTypes = [];

  /// Notes logged on leads (`leadId -> List<Activity>`) during the session.
  final Map<String, List<Activity>> leadNotesById = {};

  /// Local history entries (`"type:id" -> List<HistoryEntry>`) recorded in-session.
  final Map<String, List<HistoryEntry>> sessionHistory = {};

  /// Cached activity metadata (`activityId -> Activity`) for reschedule/complete.
  final Map<String, Activity> activitiesById = {};

  /// Cached activity type ID (`activityId -> int`) for rescheduling.
  final Map<String, int> activityTypeIdByActivityId = {};

  /// Cached related record names (`"customer:10"` or `"opportunity:100" -> name`).
  final Map<String, String> documentNames = {};

  BaseRepository get _openRepo => ref.read(openBaseRepoProvider);
  BaseRepository get _tokenRepo => ref.read(tokenBaseRepoProvider);

  String? get bearerToken {
    if (_activeToken != null && _activeToken!.isNotEmpty) return _activeToken;
    try {
      final stored = ref.read(authStorageProvider).loginData?.token;
      if (stored != null && stored.isNotEmpty) return stored;
    } on Object {
      // localStorageProvider may not be initialized in isolated unit tests.
    }
    return null;
  }

  /// Checks DevMenu airplane mode / forced failure if mockStore is available.
  Failure? _checkDevInjection() {
    try {
      final store = ref.read(mockStoreProvider);
      if (store.airplaneMode) return const Failure.network();
      final forced = store.forceNextFailure;
      if (forced != null) {
        store.forceNextFailure = null;
        return forced;
      }
    } on Object {
      // Ignore if mockStoreProvider is not overridden.
    }
    return null;
  }

  Future<Result<T, Failure>> get<T>(
    String url, {
    Map<String, dynamic>? params,
    bool auth = true,
    required T Function(dynamic json) parse,
    Map<String, String>? fieldMap,
  }) async {
    final injected = _checkDevInjection();
    if (injected != null) return Err(injected);
    try {
      final repo = auth ? _tokenRepo : _openRepo;
      final cleanParams = params == null
          ? null
          : {
              for (final e in params.entries)
                if (e.value != null) e.key: e.value,
            };
      final value = await repo.get<T>(
        RequestInput<T>(
          url: url,
          params: cleanParams,
          repositoryDetails: auth
              ? RepositoryDetails(tokenNeeded: true)
              : RepositoryDetails.noToken(),
          parseJson: parse,
        ),
      );
      return Ok(value);
    } on Object catch (e) {
      return Err(toFailure(e, fieldMap: fieldMap));
    }
  }

  Future<Result<T, Failure>> post<T>(
    String url, {
    Object? body,
    Map<String, dynamic>? params,
    bool auth = true,
    bool isMultipart = false,
    required T Function(dynamic json) parse,
    Map<String, String>? fieldMap,
  }) async {
    final injected = _checkDevInjection();
    if (injected != null) return Err(injected);
    try {
      final repo = auth ? _tokenRepo : _openRepo;
      final value = await repo.post<T>(
        RequestInput<T>(
          url: url,
          body: body,
          params: params,
          repositoryDetails: auth
              ? RepositoryDetails(tokenNeeded: true)
              : RepositoryDetails.noToken(),
          parseJson: parse,
        ),
        isMultipart: isMultipart,
      );
      return Ok(value);
    } on Object catch (e) {
      return Err(toFailure(e, fieldMap: fieldMap));
    }
  }

  Future<Result<T, Failure>> put<T>(
    String url, {
    Object? body,
    Map<String, dynamic>? params,
    bool auth = true,
    required T Function(dynamic json) parse,
    Map<String, String>? fieldMap,
  }) async {
    final injected = _checkDevInjection();
    if (injected != null) return Err(injected);
    try {
      final repo = auth ? _tokenRepo : _openRepo;
      final value = await repo.put<T>(
        RequestInput<T>(
          url: url,
          body: body,
          params: params,
          repositoryDetails: auth
              ? RepositoryDetails(tokenNeeded: true)
              : RepositoryDetails.noToken(),
          parseJson: parse,
        ),
      );
      return Ok(value);
    } on Object catch (e) {
      return Err(toFailure(e, fieldMap: fieldMap));
    }
  }

  /// Converts any Dio / CustomAPIException / network error into domain [Failure].
  Failure toFailure(Object error, {Map<String, String>? fieldMap}) {
    if (error is Failure) return error;

    DioException? dioErr;
    Response<dynamic>? response;
    String? fallbackMessage;

    if (error is CustomAPIException) {
      response = error.response;
      fallbackMessage = error.errorMessage;
      if (error.originalErrorObject is DioException) {
        dioErr = error.originalErrorObject as DioException;
        response ??= dioErr.response;
      } else if (error.originalErrorObject is SocketException) {
        return const Failure.network();
      } else if (error.originalErrorObject is TimeoutException) {
        return const Failure.timeout();
      }
    } else if (error is DioException) {
      dioErr = error;
      response = error.response;
    } else if (error is SocketException) {
      return const Failure.network();
    } else if (error is TimeoutException) {
      return const Failure.timeout();
    }

    if (dioErr != null) {
      switch (dioErr.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const Failure.timeout();
        case DioExceptionType.connectionError:
          return const Failure.network();
        case DioExceptionType.unknown:
          if (dioErr.error is SocketException) return const Failure.network();
          if (dioErr.error is TimeoutException) return const Failure.timeout();
        default:
          break;
      }
    }

    final statusCode = response?.statusCode;
    final data = response?.data;

    if (statusCode == 401 || statusCode == 403) {
      return const Failure.permissionDenied();
    }

    if (statusCode == 404) {
      return Failure.unknown(_extractMessage(data) ?? 'Not found');
    }

    if (statusCode == 409) {
      // CustomerConflictResponse: A customer with the same phone/mobile already exists.
      final msg =
          _extractMessage(data) ??
          'A customer with the same phone/mobile already exists.';
      String conflictSuffix = '';
      if (data is Map && data['data'] is Map) {
        final conflictCustomer = data['data'] as Map;
        final existingName = conflictCustomer['name']?.toString();
        if (existingName != null && existingName.isNotEmpty) {
          conflictSuffix = ' ($existingName)';
        }
      }
      final phoneField = fieldMap?['phone'] ?? 'phone';
      return Failure.validation('$msg$conflictSuffix', field: phoneField);
    }

    if (statusCode == 400) {
      if (data is Map) {
        final issues = data['data'];
        if (issues is List && issues.isNotEmpty && issues.first is Map) {
          final firstIssue = Map<String, dynamic>.from(issues.first as Map);
          String? rawField = firstIssue['name']?.toString();
          if ((rawField == null || rawField.isEmpty) &&
              firstIssue['loc'] is List &&
              (firstIssue['loc'] as List).isNotEmpty) {
            rawField = (firstIssue['loc'] as List).last.toString();
          }
          final mappedField = (rawField != null && fieldMap != null)
              ? (fieldMap[rawField] ?? rawField)
              : rawField;
          final issueError =
              firstIssue['error']?.toString() ??
              _extractMessage(data) ??
              'Validation error';
          return Failure.validation(issueError, field: mappedField);
        }
      }
      final msg =
          _extractMessage(data) ?? fallbackMessage ?? 'Validation error';
      String? inferredField;
      if (fieldMap != null) {
        final lowerMsg = msg.toLowerCase();
        for (final entry in fieldMap.entries) {
          if (lowerMsg.contains(entry.key.toLowerCase())) {
            inferredField = entry.value;
            break;
          }
        }
      }
      return Failure.validation(msg, field: inferredField);
    }

    final message = _extractMessage(data) ?? fallbackMessage;
    return Failure.unknown(message);
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Shared JSON Mappers & Cache Registration
  // ---------------------------------------------------------------------------

  static final RegExp _imageUserIdRe = RegExp(r'/image/[^/]+/(\d+)/');

  static const Permissions defaultApiPermissions = Permissions(
    canCreateCustomer: true,
    canEditCustomer: true,
    canCreateOpportunity: true,
    canEditOpportunity: true,
    canChangeStage: true,
    canReassign: true,
    canViewTeam: true,
    canLogActivity: true,
  );

  AppUser parseUser(Map<String, dynamic> json, {String? fallbackId}) {
    final email = (json['email'] ?? '').toString().trim();
    final name = (json['name'] ?? email).toString().trim();
    final phone = _nonEmptyStr(json['phone']);
    final rawImage = _nonEmptyStr(json['image']);
    final resolvedImage = rawImage != null
        ? ApiConstant.resolveUrl(rawImage)
        : null;

    String? extractedId = json['id']?.toString();
    if (extractedId == null && rawImage != null) {
      final match = _imageUserIdRe.firstMatch(rawImage);
      if (match != null) extractedId = match.group(1);
    }
    final id =
        extractedId ??
        fallbackId ??
        currentUser?.id ??
        (email.isNotEmpty ? email : '1');

    final roleStr = _nonEmptyStr(json['role'])?.toLowerCase();
    final role = roleStr == 'salesperson'
        ? UserRole.salesperson
        : UserRole.supervisor;

    final teamId = json['team_id']?.toString() ?? currentUser?.teamId ?? '1';
    final timezone = _nonEmptyStr(json['timezone']) ?? 'Asia/Kathmandu';
    final isActive = json['is_active'] as bool? ?? true;

    Permissions permissions = role == UserRole.salesperson
        ? defaultApiPermissions.copyWith(canReassign: false, canViewTeam: false)
        : defaultApiPermissions;
    if (json['permissions'] is Map) {
      final p = Map<String, dynamic>.from(json['permissions'] as Map);
      permissions = Permissions(
        canCreateCustomer:
            p['can_create_customer'] as bool? ?? permissions.canCreateCustomer,
        canEditCustomer:
            p['can_edit_customer'] as bool? ?? permissions.canEditCustomer,
        canCreateOpportunity:
            p['can_create_opportunity'] as bool? ??
            permissions.canCreateOpportunity,
        canEditOpportunity:
            p['can_edit_opportunity'] as bool? ??
            permissions.canEditOpportunity,
        canChangeStage:
            p['can_change_stage'] as bool? ?? permissions.canChangeStage,
        canReassign: p['can_reassign'] as bool? ?? permissions.canReassign,
        canViewTeam: p['can_view_team'] as bool? ?? permissions.canViewTeam,
        canLogActivity:
            p['can_log_activity'] as bool? ?? permissions.canLogActivity,
      );
    }

    final user = AppUser(
      id: id,
      name: name.isEmpty ? 'User' : name,
      email: email,
      role: role,
      teamId: teamId,
      permissions: permissions,
      timezone: timezone,
      isActive: isActive,
      phone: phone,
      avatarPath: resolvedImage,
    );
    usersById[user.id] = user;
    return user;
  }

  Team parseTeam(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final name = (json['name'] ?? 'Sales Team').toString();
    final supervisorId =
        json['supervisor_id']?.toString() ??
        teamsById[id]?.supervisorId ??
        currentUser?.id ??
        '1';
    final team = Team(id: id, name: name, supervisorId: supervisorId);
    teamsById[id] = team;
    return team;
  }

  void registerUserRef(Map<String, dynamic>? userMap, {String? teamId}) {
    if (userMap == null) return;
    final id = userMap['id']?.toString();
    final name = _nonEmptyStr(userMap['name']);
    if (id == null || name == null) return;
    final existing = usersById[id];
    if (existing != null) {
      usersById[id] = existing.copyWith(
        name: name,
        teamId: teamId ?? existing.teamId,
      );
    } else {
      usersById[id] = AppUser(
        id: id,
        name: name,
        email: (userMap['email'] ?? '').toString(),
        role: UserRole.salesperson,
        teamId: teamId ?? currentUser?.teamId ?? '1',
        permissions: defaultApiPermissions,
        timezone: 'Asia/Kathmandu',
        isActive: true,
      );
    }
  }

  void registerTeamRef(Map<String, dynamic>? teamMap) {
    if (teamMap == null) return;
    final id = teamMap['id']?.toString();
    final name = _nonEmptyStr(teamMap['name']);
    if (id == null || name == null) return;
    final existing = teamsById[id];
    teamsById[id] = Team(
      id: id,
      name: name,
      supervisorId: existing?.supervisorId ?? currentUser?.id ?? '1',
    );
  }

  Customer parseCustomer(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final name = (json['name'] ?? '').toString();
    final typeStr = (json['type'] ?? 'individual').toString().toLowerCase();
    final isCompany = typeStr == 'company';

    String? parentId;
    if (json['company'] is Map) {
      final comp = json['company'] as Map;
      parentId = comp['id']?.toString();
    }

    final phone =
        _nonEmptyStr(json['phone']) ?? _nonEmptyStr(json['mobile']);
    final email = _nonEmptyStr(json['email']);
    final street = _nonEmptyStr(json['street']);
    final street2 = _nonEmptyStr(json['street2']);
    final combinedStreet = [street, street2].whereType<String>().join(', ');
    final address = combinedStreet.isNotEmpty
        ? combinedStreet
        : _nonEmptyStr(json['address']);
    final city = _nonEmptyStr(json['city']);
    final country = _nonEmptyStr(json['country']);
    final taxId = _nonEmptyStr(json['vat']) ?? _nonEmptyStr(json['tax_id']);

    return Customer(
      id: id,
      name: name,
      isCompany: isCompany,
      parentId: parentId,
      phone: phone,
      email: email,
      address: address,
      city: city,
      country: country,
      taxId: taxId,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  PipelineStage parseStage(
    Map<String, dynamic> json, {
    List<String> allowedNextStageIds = const [],
  }) {
    if (json['team'] is Map) {
      registerTeamRef(Map<String, dynamic>.from(json['team'] as Map));
    }
    return PipelineStage(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      isWon: json['is_won'] as bool? ?? false,
      isFolded: json['fold'] as bool? ?? false,
      allowedNextStageIds: allowedNextStageIds,
    );
  }

  Opportunity parseLead(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final title = (json['name'] ?? '').toString();

    String customerId = '';
    if (json['partner'] is Map) {
      final partner = Map<String, dynamic>.from(json['partner'] as Map);
      customerId = partner['id']?.toString() ?? '';
      final partnerName = _nonEmptyStr(partner['name']);
      if (partnerName != null && customerId.isNotEmpty) {
        documentNames['${RelatedType.customer.name}:$customerId'] = partnerName;
      }
    }
    if (title.isNotEmpty) {
      documentNames['${RelatedType.opportunity.name}:$id'] = title;
    }

    String stageId = '';
    if (json['stage'] is Map) {
      final stage = Map<String, dynamic>.from(json['stage'] as Map);
      stageId = stage['id']?.toString() ?? '';
    }

    String teamId = currentUser?.teamId ?? '1';
    if (json['team'] is Map) {
      final team = Map<String, dynamic>.from(json['team'] as Map);
      registerTeamRef(team);
      teamId = team['id']?.toString() ?? teamId;
    }

    String ownerId = currentUser?.id ?? '';
    if (json['user'] is Map) {
      final user = Map<String, dynamic>.from(json['user'] as Map);
      registerUserRef(user, teamId: teamId);
      ownerId = user['id']?.toString() ?? ownerId;
    }

    final expectedRevenue =
        (json['expected_revenue'] as num?)?.toDouble() ?? 0.0;
    final probability = (json['probability'] as num?)?.round() ?? 0;

    final deadlineStr = _nonEmptyStr(json['date_deadline']);
    final nextActionAt = parseUtcDate(deadlineStr);
    final description = _nonEmptyStr(json['description']);

    final updatedAtStr =
        _nonEmptyStr(json['date_closed']) ?? _nonEmptyStr(json['create_date']);
    final updatedAt = parseUtcDate(updatedAtStr) ?? DateTime.now().toUtc();

    return Opportunity(
      id: id,
      title: title,
      customerId: customerId,
      stageId: stageId,
      ownerId: ownerId,
      teamId: teamId,
      expectedRevenue: expectedRevenue,
      probability: probability,
      nextActionAt: nextActionAt,
      nextActionSummary: description,
      updatedAt: updatedAt,
    );
  }

  Activity parseActivity(Map<String, dynamic> json) {
    final rawId = json['id'];
    final messageId = json['message_id'];
    final id = rawId != null
        ? rawId.toString()
        : (messageId != null
              ? 'msg-$messageId'
              : 'act-${DateTime.now().microsecondsSinceEpoch}');

    String typeName = '';
    int? odooTypeId;
    if (json['activity_type'] is Map) {
      final at = Map<String, dynamic>.from(json['activity_type'] as Map);
      typeName = (at['name'] ?? '').toString().toLowerCase();
      odooTypeId = (at['id'] as num?)?.toInt();
    }
    final category = (json['category'] ?? '').toString().toLowerCase();

    ActivityType type = ActivityType.todo;
    if (category == 'phonecall' || typeName.contains('call')) {
      type = ActivityType.call;
    } else if (category == 'meeting' || typeName.contains('meeting')) {
      type = ActivityType.meeting;
    } else if (typeName.contains('visit') || typeName.contains('site')) {
      type = ActivityType.visit;
    }

    RelatedType relatedType = RelatedType.opportunity;
    String relatedId = '';
    if (json['document'] is Map) {
      final doc = Map<String, dynamic>.from(json['document'] as Map);
      final model = (doc['model'] ?? '').toString().toLowerCase();
      relatedType = model == 'customer'
          ? RelatedType.customer
          : RelatedType.opportunity;
      relatedId = doc['id']?.toString() ?? '';
      final docName = _nonEmptyStr(doc['name']);
      if (docName != null && relatedId.isNotEmpty) {
        documentNames['${relatedType.name}:$relatedId'] = docName;
      }
    }

    String ownerId = currentUser?.id ?? '';
    if (json['user'] is Map) {
      final u = Map<String, dynamic>.from(json['user'] as Map);
      registerUserRef(u);
      ownerId = u['id']?.toString() ?? ownerId;
    }

    final stateStr = (json['state'] ?? 'planned').toString().toLowerCase();
    final state = switch (stateStr) {
      'done' => ActivityState.done,
      'overdue' => ActivityState.overdue,
      _ => ActivityState.planned,
    };

    final summary =
        _nonEmptyStr(json['summary']) ??
        _nonEmptyStr(json['note']) ??
        (typeName.isNotEmpty ? typeName : 'Activity');
    final feedback =
        _nonEmptyStr(json['feedback']) ??
        (state == ActivityState.done ? _nonEmptyStr(json['note']) : null);

    final deadlineStr = _nonEmptyStr(json['date_deadline']);
    final doneStr = _nonEmptyStr(json['date_done']);
    final createStr = _nonEmptyStr(json['create_date']);

    final dueAt =
        parseUtcDate(deadlineStr) ??
        parseUtcDate(doneStr) ??
        parseUtcDate(createStr);

    final updatedAt =
        parseUtcDate(createStr) ?? dueAt ?? DateTime.now().toUtc();

    final activity = Activity(
      id: id,
      type: type,
      relatedType: relatedType,
      relatedId: relatedId,
      summary: summary,
      outcome: feedback,
      dueAt: dueAt,
      ownerId: ownerId,
      state: state,
      updatedAt: updatedAt,
    );

    if (rawId != null) {
      activitiesById[id] = activity;
      if (odooTypeId != null) {
        activityTypeIdByActivityId[id] = odooTypeId;
      }
    }

    return activity;
  }

  Activity parseNote(
    Map<String, dynamic> json, {
    String? leadId,
    String? relatedId,
    RelatedType relatedType = RelatedType.opportunity,
  }) {
    final targetId = relatedId ?? leadId ?? '';
    final id = 'note-${json['id'] ?? DateTime.now().microsecondsSinceEpoch}';
    final body = _nonEmptyStr(json['body']) ?? 'Attachment';

    String ownerId = currentUser?.id ?? '';
    if (json['author'] is Map) {
      final author = Map<String, dynamic>.from(json['author'] as Map);
      registerUserRef(author);
      ownerId = author['id']?.toString() ?? ownerId;
    }

    final dateStr = _nonEmptyStr(json['date']);
    final at = parseUtcDate(dateStr) ?? DateTime.now().toUtc();

    final attachments = <String>[];
    if (json['attachments'] is List) {
      for (final item in json['attachments'] as List) {
        if (item is Map) {
          final url = _nonEmptyStr(item['url']);
          final attId = item['id'];
          if (url != null) {
            attachments.add(ApiConstant.resolveUrl(url));
          } else if (attId != null) {
            attachments.add(ApiConstant.attachmentUrl(attId));
          }
        }
      }
    }

    final noteActivity = Activity(
      id: id,
      type: ActivityType.note,
      relatedType: relatedType,
      relatedId: targetId,
      summary: body,
      ownerId: ownerId,
      dueAt: at,
      updatedAt: at,
      state: ActivityState.done,
      attachments: attachments,
    );

    final cacheKey = relatedType == RelatedType.customer
        ? 'customer:$targetId'
        : targetId;
    final list = leadNotesById.putIfAbsent(cacheKey, () => []);
    list.removeWhere((x) => x.id == noteActivity.id);
    list.add(noteActivity);

    addSessionHistory(
      relatedType,
      targetId,
      HistoryEntry(
        id: 'h-$id',
        kind: HistoryKind.note,
        at: at,
        actorName: usersById[ownerId]?.name ?? currentUser?.name ?? ownerId,
        text: body,
      ),
    );

    return noteActivity;
  }

  HistoryEntry parseHistoryItem(Map<String, dynamic> json) {
    final id = 'h-${json['id'] ?? DateTime.now().microsecondsSinceEpoch}';
    final kindStr = (json['kind'] ?? 'activity').toString().toLowerCase();
    final kind = switch (kindStr) {
      'stage_change' => HistoryKind.stageChange,
      'owner_change' => HistoryKind.ownerChange,
      'note' => HistoryKind.note,
      _ => HistoryKind.activity,
    };
    final atStr = _nonEmptyStr(json['at']);
    final at = parseUtcDate(atStr) ?? DateTime.now().toUtc();
    final actorName =
        _nonEmptyStr(json['actor_name']) ?? currentUser?.name ?? 'User';

    return HistoryEntry(
      id: id,
      kind: kind,
      at: at,
      actorName: actorName,
      from: _nonEmptyStr(json['from']),
      to: _nonEmptyStr(json['to']),
      text: _nonEmptyStr(json['text']),
    );
  }

  static final RegExp _dateOnlyRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _tzOffsetRe = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

  static DateTime? parseUtcDate(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (_dateOnlyRe.hasMatch(s)) {
      return DateTime.tryParse('${s}T00:00:00Z');
    }
    final normalized = s.contains(' ') ? s.replaceFirst(' ', 'T') : s;
    final withZone = _tzOffsetRe.hasMatch(normalized)
        ? normalized
        : '${normalized}Z';
    return DateTime.tryParse(withZone)?.toUtc();
  }

  void addSessionHistory(RelatedType type, String recordId, HistoryEntry entry) {
    final key = '${type.name}:$recordId';
    final list = sessionHistory.putIfAbsent(key, () => []);
    list.removeWhere((e) => e.id == entry.id);
    list.add(entry);
  }

  List<HistoryEntry> getSessionHistory(RelatedType type, String recordId) {
    final key = '${type.name}:$recordId';
    return sessionHistory[key] ?? const [];
  }

  static String formatDate(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String? _nonEmptyStr(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}

final crmApiClientProvider = Provider<CrmApiClient>((ref) {
  return CrmApiClient(ref);
});
