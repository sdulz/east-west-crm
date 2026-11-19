import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';
import 'package:field_crm/common/repository/local_storage.dart';
import 'package:field_crm/common/utils/base_repo_provider.dart';
import 'package:field_crm/common/utils/base_repository/base_repository.dart';
import 'package:field_crm/common/utils/base_repository/repository_details.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/domain/session.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  Map<String, dynamic> body, {
  int statusCode = 200,
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late _FakeAdapter adapter;
  late ProviderContainer container;

  ProviderContainer createContainer(
    ResponseBody Function(RequestOptions options) handler,
  ) {
    adapter = _FakeAdapter(handler);
    final c = ProviderContainer(
      overrides: [
        useMockApiProvider.overrideWithValue(false),
        localStorageProvider.overrideWithValue(InMemoryLocalStorage()),
        openBaseRepoProvider.overrideWith((ref) {
          final dio = Dio()..httpClientAdapter = adapter;
          return BaseRepository(
            ref: ref,
            dio: dio,
            repositoryDetails: RepositoryDetails.noToken(),
          );
        }),
        tokenBaseRepoProvider.overrideWith((ref) {
          final dio = Dio()..httpClientAdapter = adapter;
          return BaseRepository(
            ref: ref,
            dio: dio,
            repositoryDetails: RepositoryDetails(tokenNeeded: true),
          );
        }),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('Auth: login, profile, refresh-token, change-password, logout', () async {
    var profileName = 'Sita Sharma';
    container = createContainer((req) {
      final path = Uri.parse(req.path).path;
      if (path == '/api/v1/auth/login' && req.method == 'POST') {
        return _jsonResponse({
          'status': true,
          'message': 'Login successful',
          'data': {
            'token': 'tok-123',
            'refresh_token': 'ref-456',
            'expires_at': 86400,
            'user': {
              'name': 'Sita Sharma',
              'email': 'sita@ewe.com.np',
              'phone': '+9779800000000',
              'address': 'Kathmandu',
              'image': '/api/v1/image/res.users/7/image_1920',
            },
          },
        });
      }
      if (path == '/api/v1/profile' && req.method == 'GET') {
        return _jsonResponse({
          'status': true,
          'message': 'OK',
          'data': {
            'name': profileName,
            'email': 'sita@ewe.com.np',
            'phone': '+9779811111111',
            'address': 'Lalitpur',
            'image': '/api/v1/image/res.users/7/image_1920',
          },
        });
      }
      if (path == '/api/v1/profile/update' && req.method == 'POST') {
        profileName = 'Sita Sharma Updated';
        return _jsonResponse({'status': true, 'message': 'Updated', 'data': null});
      }
      if (path == '/api/v1/auth/change-password' && req.method == 'POST') {
        return _jsonResponse({'status': true, 'message': 'Changed', 'data': null});
      }
      if (path == '/api/v1/auth/forget-password' && req.method == 'POST') {
        return _jsonResponse({'status': true, 'message': 'Sent', 'data': null});
      }
      if (path == '/api/v1/auth/logout' && req.method == 'POST') {
        return _jsonResponse({'status': true, 'message': 'Logged out', 'data': null});
      }
      return _jsonResponse({'status': false, 'message': 'Unexpected $path'}, statusCode: 404);
    });

    final auth = container.read(authRepositoryProvider);

    final loginRes = await auth.login(
      email: 'sita@ewe.com.np',
      password: 'secret',
      rememberMe: true,
    );
    expect(loginRes.isOk, isTrue);
    final session = (loginRes as Ok<Session, Failure>).value;
    expect(session.token, 'tok-123');
    expect(session.user.id, '7');
    expect(session.user.name, 'Sita Sharma');
    expect(
      session.user.avatarPath,
      '${ApiConstant.baseUrl}/api/v1/image/res.users/7/image_1920',
    );

    profileName = 'Sita Sharma Updated';
    final restoreRes = await auth.restoreSession('tok-123');
    expect(restoreRes.isOk, isTrue);
    expect(restoreRes.getOrThrow()?.user.name, 'Sita Sharma Updated');

    final updateRes = await auth.updateProfile(
      name: 'Sita Sharma Updated',
      phone: '+9779811111111',
    );
    expect(updateRes.isOk, isTrue);

    final pwRes = await auth.changePassword(
      current: 'secret',
      next: 'newpassword123',
    );
    expect(pwRes.isOk, isTrue);

    final forgotRes = await auth.requestPasswordReset('sita@ewe.com.np');
    expect(forgotRes.isOk, isTrue);

    final logoutRes = await auth.logout('tok-123');
    expect(logoutRes.isOk, isTrue);
  });

  test('Customers: list, getById, create, update, and 409 conflict', () async {
    var failWithConflict = false;
    container = createContainer((req) {
      final path = Uri.parse(req.path).path;
      if (path == '/api/v1/customers' && req.method == 'GET') {
        return _jsonResponse({
          'status': true,
          'message': 'OK',
          'data': [
            {
              'id': 10,
              'name': 'East West Enterprises',
              'type': 'company',
              'phone': '+97714400000',
              'mobile': null,
              'email': 'info@ewe.com.np',
              'street': 'Durbar Marg',
              'street2': null,
              'city': 'Kathmandu',
              'state': null,
              'zip': '44600',
              'country': 'Nepal',
              'company': null,
            },
          ],
          'currentPage': 1,
          'lastPage': 1,
          'total': 1,
        });
      }
      if (path == '/api/v1/customers' && req.method == 'POST') {
        if (failWithConflict) {
          return _jsonResponse(
            {
              'status': false,
              'message': 'A customer with this phone already exists',
              'data': {
                'id': 10,
                'name': 'East West Enterprises',
                'type': 'company',
              },
            },
            statusCode: 409,
          );
        }
        return _jsonResponse(
          {
            'status': true,
            'message': 'Created',
            'data': {
              'id': 11,
              'name': 'Hari Bahadur',
              'type': 'individual',
              'phone': '+9779841000000',
              'mobile': null,
              'email': 'hari@example.com',
              'street': 'Pulchowk',
              'street2': null,
              'city': 'Lalitpur',
              'state': null,
              'zip': null,
              'country': 'Nepal',
              'company': {'id': 10, 'name': 'East West Enterprises'},
            },
          },
          statusCode: 201,
        );
      }
      if (path == '/api/v1/customers/11' && req.method == 'PUT') {
        return _jsonResponse({
          'status': true,
          'message': 'Updated',
          'data': {
            'id': 11,
            'name': 'Hari Bahadur KC',
            'type': 'individual',
            'phone': '+9779841000000',
            'company': {'id': 10, 'name': 'East West Enterprises'},
          },
        });
      }
      return _jsonResponse({'status': false, 'message': 'Not found'}, statusCode: 404);
    });

    final repo = container.read(customerRepositoryProvider);

    final listRes = await repo.list();
    expect(listRes.isOk, isTrue);
    final customers = (listRes as Ok<List<Customer>, Failure>).value;
    expect(customers.single.id, '10');
    expect(customers.single.isCompany, isTrue);

    final createRes = await repo.create(
      Customer(
        id: 'temp',
        name: 'Hari Bahadur',
        isCompany: false,
        parentId: '10',
        phone: '+9779841000000',
        email: 'hari@example.com',
        address: 'Pulchowk',
        city: 'Lalitpur',
        country: 'Nepal',
        updatedAt: DateTime.utc(2026),
      ),
    );
    expect(createRes.isOk, isTrue);
    final created = (createRes as Ok<Customer, Failure>).value;
    expect(created.id, '11');
    expect(created.parentId, '10');

    final updateRes = await repo.update(
      created.copyWith(name: 'Hari Bahadur KC'),
      expectedUpdatedAt: created.updatedAt,
    );
    expect(updateRes.isOk, isTrue);
    expect((updateRes as Ok<Customer, Failure>).value.name, 'Hari Bahadur KC');

    failWithConflict = true;
    final conflictRes = await repo.create(created);
    expect(conflictRes.isErr, isTrue);
    final err = (conflictRes as Err<Customer, Failure>).error;
    expect(err, isA<ValidationFailure>());
    expect((err as ValidationFailure).field, 'phone');
    expect(err.message, contains('East West Enterprises'));
  });

  test('Pipeline & Opportunities: stages, leads CRUD, stage change, reassign', () async {
    container = createContainer((req) {
      final path = Uri.parse(req.path).path;
      if (path == '/api/v1/crm/stages' && req.method == 'GET') {
        return _jsonResponse({
          'status': true,
          'message': 'OK',
          'data': [
            {
              'id': 1,
              'name': 'New',
              'sequence': 1,
              'is_won': false,
              'fold': false,
              'team': {'id': 1, 'name': 'Direct Sales'},
              'lead_count': 2,
            },
            {
              'id': 2,
              'name': 'Qualified',
              'sequence': 2,
              'is_won': false,
              'fold': false,
              'team': {'id': 1, 'name': 'Direct Sales'},
              'lead_count': 1,
            },
            {
              'id': 3,
              'name': 'Won',
              'sequence': 3,
              'is_won': true,
              'fold': false,
              'team': {'id': 1, 'name': 'Direct Sales'},
              'lead_count': 1,
            },
          ],
        });
      }
      if (path == '/api/v1/crm/leads' && req.method == 'GET') {
        return _jsonResponse({
          'status': true,
          'message': 'OK',
          'data': [
            {
              'id': 100,
              'name': 'Solar Inverter Deal',
              'type': 'opportunity',
              'active': true,
              'priority': '2',
              'probability': 40.0,
              'expected_revenue': 250000.0,
              'stage': {'id': 1, 'name': 'New', 'is_won': false},
              'partner': {'id': 10, 'name': 'East West Enterprises'},
              'contact_name': 'Hari Bahadur',
              'email': 'info@ewe.com.np',
              'phone': '+97714400000',
              'mobile': null,
              'user': {'id': 7, 'name': 'Sita Sharma'},
              'team': {'id': 1, 'name': 'Direct Sales'},
              'date_deadline': '2026-11-15',
              'date_closed': null,
              'create_date': '2026-10-20 10:00:00',
              'description': 'Follow up on quote',
            },
          ],
          'currentPage': 1,
          'lastPage': 1,
          'total': 1,
        });
      }
      if (path == '/api/v1/crm/leads/100/stage' && req.method == 'PUT') {
        return _jsonResponse({
          'status': true,
          'message': 'Stage updated',
          'data': {
            'id': 100,
            'name': 'Solar Inverter Deal',
            'probability': 60.0,
            'expected_revenue': 250000.0,
            'stage': {'id': 2, 'name': 'Qualified', 'is_won': false},
            'partner': {'id': 10, 'name': 'East West Enterprises'},
            'user': {'id': 7, 'name': 'Sita Sharma'},
            'team': {'id': 1, 'name': 'Direct Sales'},
          },
        });
      }
      if (path == '/api/v1/crm/leads/100' && req.method == 'PUT') {
        return _jsonResponse({
          'status': true,
          'message': 'Lead updated',
          'data': {
            'id': 100,
            'name': 'Solar Inverter Deal',
            'probability': 60.0,
            'expected_revenue': 250000.0,
            'stage': {'id': 2, 'name': 'Qualified', 'is_won': false},
            'partner': {'id': 10, 'name': 'East West Enterprises'},
            'user': {'id': 8, 'name': 'Ram Thapa'},
            'team': {'id': 1, 'name': 'Direct Sales'},
          },
        });
      }
      return _jsonResponse({'status': false, 'message': 'Not found'}, statusCode: 404);
    });

    final pipelineRepo = container.read(pipelineRepositoryProvider);
    final stagesRes = await pipelineRepo.stages();
    expect(stagesRes.isOk, isTrue);
    final stages = (stagesRes as Ok<List<PipelineStage>, Failure>).value;
    expect(stages.length, 3);
    expect(stages.first.canMoveTo('2'), isTrue);
    expect(stages.first.canMoveTo('3'), isTrue);

    final oppRepo = container.read(opportunityRepositoryProvider);
    final oppsRes = await oppRepo.list();
    expect(oppsRes.isOk, isTrue);
    final opp = (oppsRes as Ok<List<Opportunity>, Failure>).value.single;
    expect(opp.id, '100');
    expect(opp.stageId, '1');
    expect(opp.customerId, '10');

    final stageChangeRes = await oppRepo.changeStage(
      '100',
      toStageId: '2',
      expectedUpdatedAt: opp.updatedAt,
    );
    expect(stageChangeRes.isOk, isTrue);
    expect((stageChangeRes as Ok<Opportunity, Failure>).value.stageId, '2');

    final reassignRes = await oppRepo.reassign(
      '100',
      newOwnerId: '8',
      expectedUpdatedAt: opp.updatedAt,
    );
    expect(reassignRes.isOk, isTrue);
    expect((reassignRes as Ok<Opportunity, Failure>).value.ownerId, '8');
  });

  test('Activities & Notes: types, list, create activity, create note, complete', () async {
    container = createContainer((req) {
      final path = Uri.parse(req.path).path;
      if (path == '/api/v1/activity-types' && req.method == 'GET') {
        return _jsonResponse({
          'status': true,
          'message': 'OK',
          'data': [
            {
              'id': 1,
              'name': 'Email',
              'category': 'default',
              'sequence': 1,
              'model': null,
            },
            {
              'id': 2,
              'name': 'Call',
              'category': 'phonecall',
              'sequence': 2,
              'model': null,
            },
            {
              'id': 3,
              'name': 'To-Do',
              'category': 'default',
              'sequence': 3,
              'model': null,
            },
          ],
        });
      }
      if (path == '/api/v1/crm/leads/100/activities' && req.method == 'GET') {
        return _jsonResponse({
          'status': true,
          'message': 'OK',
          'data': [
            {
              'id': 501,
              'message_id': null,
              'state': 'planned',
              'activity_type': {'id': 3, 'name': 'To-Do'},
              'category': 'default',
              'icon': 'fa-check',
              'summary': 'Send revised quotation',
              'note': null,
              'feedback': null,
              'date_deadline': '2026-11-01',
              'date_done': null,
              'create_date': '2026-10-25 09:00:00',
              'user': {'id': 7, 'name': 'Sita Sharma'},
              'author': {'id': 10, 'name': 'Sita Sharma'},
              'document': {
                'model': 'lead',
                'id': 100,
                'name': 'Solar Inverter Deal',
              },
            },
          ],
        });
      }
      if (path == '/api/v1/crm/leads/100/activities' && req.method == 'POST') {
        return _jsonResponse(
          {
            'status': true,
            'message': 'Scheduled',
            'data': {
              'id': 502,
              'message_id': null,
              'state': 'planned',
              'activity_type': {'id': 3, 'name': 'To-Do'},
              'category': 'default',
              'summary': 'Site inspection',
              'date_deadline': '2026-11-05',
              'user': {'id': 7, 'name': 'Sita Sharma'},
              'document': {
                'model': 'lead',
                'id': 100,
                'name': 'Solar Inverter Deal',
              },
            },
          },
          statusCode: 201,
        );
      }
      if (path == '/api/v1/activities/501/done' && req.method == 'POST') {
        return _jsonResponse({
          'status': true,
          'message': 'Completed',
          'data': {
            'id': null,
            'message_id': 9001,
            'state': 'done',
            'activity_type': {'id': 3, 'name': 'To-Do'},
            'category': 'default',
            'summary': 'Send revised quotation',
            'feedback': 'Sent via email',
            'date_done': '2026-10-30 12:00:00',
            'user': {'id': 7, 'name': 'Sita Sharma'},
            'document': {
              'model': 'lead',
              'id': 100,
              'name': 'Solar Inverter Deal',
            },
          },
        });
      }
      if (path == '/api/v1/crm/leads/100/notes' && req.method == 'POST') {
        return _jsonResponse(
          {
            'status': true,
            'message': 'Note created',
            'data': {
              'id': 7001,
              'body': 'Customer requested 5% discount',
              'author': {'id': 10, 'name': 'Sita Sharma'},
              'date': '2026-10-30 12:30:00',
              'attachments': [
                {
                  'id': 301,
                  'name': 'quote.pdf',
                  'mimetype': 'application/pdf',
                  'size': 1024,
                  'url': '/api/v1/attachments/301',
                },
              ],
            },
          },
          statusCode: 201,
        );
      }
      return _jsonResponse({'status': false, 'message': 'Not found'}, statusCode: 404);
    });

    final actRepo = container.read(activityRepositoryProvider);

    final typesRes = await actRepo.types();
    expect(typesRes.isOk, isTrue);
    final typeDefs = (typesRes as Ok<List<ActivityTypeDef>, Failure>).value;
    expect(typeDefs.any((t) => t.isFollowUp), isTrue);

    final createTodoRes = await actRepo.create(
      Activity(
        id: 'local-1',
        type: ActivityType.todo,
        relatedType: RelatedType.opportunity,
        relatedId: '100',
        summary: 'Site inspection',
        dueAt: DateTime.utc(2026, 11, 5),
        ownerId: '7',
        updatedAt: DateTime.utc(2026, 10, 30),
      ),
    );
    expect(createTodoRes.isOk, isTrue);
    expect((createTodoRes as Ok<Activity, Failure>).value.id, '502');

    final createNoteRes = await actRepo.create(
      Activity(
        id: 'local-note',
        type: ActivityType.note,
        relatedType: RelatedType.opportunity,
        relatedId: '100',
        summary: 'Customer requested 5% discount',
        ownerId: '7',
        updatedAt: DateTime.utc(2026, 10, 30),
      ),
    );
    expect(createNoteRes.isOk, isTrue);
    final createdNote = (createNoteRes as Ok<Activity, Failure>).value;
    expect(createdNote.type, ActivityType.note);
    expect(
      createdNote.attachments.single,
      '${ApiConstant.baseUrl}/api/v1/attachments/301',
    );

    final completeRes = await actRepo.complete(
      '501',
      outcome: 'Sent via email',
      expectedUpdatedAt: DateTime.utc(2026, 10, 30),
    );
    expect(completeRes.isOk, isTrue);
    final completed = (completeRes as Ok<Activity, Failure>).value;
    expect(completed.state, ActivityState.done);
    expect(completed.outcome, 'Sent via email');

    final historyRepo = container.read(historyRepositoryProvider);
    final historyRes = await historyRepo.forRecord(
      RelatedType.opportunity,
      '100',
    );
    expect(historyRes.isOk, isTrue);
    final entries = (historyRes as Ok<List<HistoryEntry>, Failure>).value;
    expect(entries.any((e) => e.kind == HistoryKind.note), isTrue);
    expect(entries.any((e) => e.kind == HistoryKind.activity), isTrue);
  });
}
