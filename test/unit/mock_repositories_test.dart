import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late TestHarness h;
  setUp(() async => h = await TestHarness.create());
  tearDown(() => h.dispose());

  group('seed (MOCK DATA SOURCE)', () {
    test('has the required shape', () {
      final s = h.store.state;
      expect(
        s.users.where((u) => u.role.name == 'salesperson' && u.isActive).length,
        2,
      );
      expect(s.users.where((u) => u.role.name == 'supervisor').length, 1);
      expect(s.teams.length, 1);
      expect(s.customers.length, 40);
      expect(s.opportunities.length, 60);
      expect(s.activities.length, 120);
      expect(s.stages.length, greaterThanOrEqualTo(4));
      expect(
        s.activityTypes.map((t) => t.type.name),
        containsAll(['call', 'visit', 'meeting', 'note', 'todo']),
      );
    });

    test('snapshot survives a JSON round-trip', () async {
      await h.store.call(() => 1, write: true);
      final json = await h.store.stateStore.load();
      expect(json, isNotNull);
    });
  });

  group('auth', () {
    test(
      'invalid and inactive users are rejected with distinct messages',
      () async {
        final auth = h.container.read(authRepositoryProvider);
        final bad = await auth.login(
          email: 'sita@fieldcrm.test',
          password: 'nope',
          rememberMe: false,
        );
        expect(
          bad.errorOrNull,
          const Failure.validation('invalid_credentials'),
        );
        final inactive = await auth.login(
          email: 'hari@fieldcrm.test',
          password: 'password',
          rememberMe: false,
        );
        expect(
          inactive.errorOrNull,
          const Failure.validation('inactive_account'),
        );
        final ok = await auth.login(
          email: 'sita@fieldcrm.test',
          password: 'password',
          rememberMe: true,
        );
        expect(ok.valueOrNull?.user.id, 'u-sita');
        final restored = await auth.restoreSession(ok.valueOrNull!.token);
        expect(restored.valueOrNull?.user.id, 'u-sita');
        await auth.logout(ok.valueOrNull!.token);
        expect(
          (await auth.restoreSession(ok.valueOrNull!.token)).valueOrNull,
          isNull,
        );
      },
    );
  });

  group('TC-01 scope', () {
    test('salesperson sees only own opportunities and activities', () async {
      h.store.setCurrentUser('u-sita');
      final opps =
          (await h.container.read(opportunityRepositoryProvider).list())
              .getOrThrow();
      expect(opps, isNotEmpty);
      expect(opps.every((o) => o.ownerId == 'u-sita'), isTrue);
      final acts = (await h.container.read(activityRepositoryProvider).list())
          .getOrThrow();
      expect(acts.every((a) => a.ownerId == 'u-sita'), isTrue);
      // Someone else's record is permission denied, not merely hidden.
      final other = h.store.state.opportunities.firstWhere(
        (o) => o.ownerId == 'u-ram',
      );
      final r = await h.container
          .read(opportunityRepositoryProvider)
          .getById(other.id);
      expect(r.errorOrNull, const Failure.permissionDenied());
    });

    test('supervisor sees the whole team', () async {
      h.store.setCurrentUser('u-maya');
      final opps =
          (await h.container.read(opportunityRepositoryProvider).list())
              .getOrThrow();
      expect(opps.length, 60);
      expect(opps.map((o) => o.ownerId).toSet(), {'u-sita', 'u-ram'});
    });

    test('TC-05 team overview only for canViewTeam', () async {
      h.store.setCurrentUser('u-sita');
      expect(
        (await h.container.read(teamRepositoryProvider).overview()).errorOrNull,
        const Failure.permissionDenied(),
      );
      h.store.setCurrentUser('u-maya');
      final t = (await h.container.read(teamRepositoryProvider).overview())
          .getOrThrow();
      expect(t.members.map((m) => m.user.id), ['u-sita', 'u-ram']);
      for (final m in t.members) {
        expect(
          m.openOpportunities.every((o) => o.ownerId == m.user.id),
          isTrue,
        );
        expect(
          m.overdueActivities.every((a) => a.state == ActivityState.overdue),
          isTrue,
        );
      }
    });
  });

  group('customers (FR-MOB-004)', () {
    setUp(() => h.store.setCurrentUser('u-sita'));

    test('validation messages are returned for bad phone/email', () async {
      final repo = h.container.read(customerRepositoryProvider);
      final r = await repo.create(
        Customer(
          id: uuidV4(),
          name: 'X',
          phone: 'abc',
          updatedAt: DateTime.utc(2026),
        ),
      );
      expect(
        r.errorOrNull,
        isA<ValidationFailure>().having((f) => f.field, 'field', 'phone'),
      );
      final r2 = await repo.create(
        Customer(id: uuidV4(), name: '', updatedAt: DateTime.utc(2026)),
      );
      expect(
        r2.errorOrNull,
        const Failure.validation('Name is required', field: 'name'),
      );
    });

    test('create is idempotent on the client UUID', () async {
      final repo = h.container.read(customerRepositoryProvider);
      final c = Customer(
        id: uuidV4(),
        name: 'Dup Co',
        updatedAt: DateTime.utc(2026),
      );
      await repo.create(c);
      await repo.create(c);
      expect(h.store.state.customers.where((x) => x.id == c.id).length, 1);
    });

    test('stale expectedUpdatedAt is a conflict', () async {
      final repo = h.container.read(customerRepositoryProvider);
      final c = h.store.state.customers.first;
      final r = await repo.update(c, expectedUpdatedAt: DateTime.utc(1999));
      expect(r.errorOrNull, const Failure.conflict());
      final ok = await repo.update(
        c.copyWith(city: 'Pokhara'),
        expectedUpdatedAt: c.updatedAt,
      );
      expect(ok.valueOrNull?.city, 'Pokhara');
    });
  });

  group('TC-03 stage + handover', () {
    test(
      'allowed transition moves and writes history; disallowed rejects',
      () async {
        h.store.setCurrentUser('u-sita');
        final repo = h.container.read(opportunityRepositoryProvider);
        final o = h.store.state.opportunities.firstWhere(
          (o) => o.ownerId == 'u-sita' && o.stageId == 's-new',
        );
        final bad = await repo.changeStage(
          o.id,
          toStageId: 's-won',
          expectedUpdatedAt: o.updatedAt,
        );
        expect(
          bad.errorOrNull,
          isA<ValidationFailure>().having(
            (f) => f.message,
            'msg',
            contains('not allowed'),
          ),
        );
        expect(
          h.store.state.opportunities.firstWhere((x) => x.id == o.id).stageId,
          's-new',
        );

        final ok = await repo.changeStage(
          o.id,
          toStageId: 's-qualified',
          expectedUpdatedAt: o.updatedAt,
        );
        expect(ok.valueOrNull?.stageId, 's-qualified');
        final hist =
            (await h.container
                    .read(historyRepositoryProvider)
                    .forRecord(RelatedType.opportunity, o.id))
                .getOrThrow();
        expect(hist.first.kind, HistoryKind.stageChange);
        expect(hist.first.from, 'New');
        expect(hist.first.to, 'Qualified');
      },
    );

    test(
      'handover requires canReassign and returns the confirmed owner',
      () async {
        h.store.setCurrentUser('u-sita');
        final repo = h.container.read(opportunityRepositoryProvider);
        final o = h.store.state.opportunities.firstWhere(
          (o) => o.ownerId == 'u-sita',
        );
        expect(
          (await repo.reassign(
            o.id,
            newOwnerId: 'u-ram',
            expectedUpdatedAt: o.updatedAt,
          )).errorOrNull,
          const Failure.permissionDenied(),
        );
        h.store.setCurrentUser('u-maya');
        final users =
            (await h.container
                    .read(userDirectoryRepositoryProvider)
                    .assignableUsers())
                .getOrThrow();
        expect(users.map((u) => u.id), containsAll(['u-sita', 'u-ram']));
        final r = await repo.reassign(
          o.id,
          newOwnerId: 'u-ram',
          expectedUpdatedAt: o.updatedAt,
        );
        expect(r.valueOrNull?.ownerId, 'u-ram');
        final hist =
            (await h.container
                    .read(historyRepositoryProvider)
                    .forRecord(RelatedType.opportunity, o.id))
                .getOrThrow();
        expect(hist.first.kind, HistoryKind.ownerChange);
        expect(hist.first.to, 'Ram Thapa');
      },
    );
  });

  group('activities (FR-MOB-006/007)', () {
    setUp(() => h.store.setCurrentUser('u-sita'));

    test(
      'follow-up needs a due date; interaction is done immediately',
      () async {
        final repo = h.container.read(activityRepositoryProvider);
        final o = h.store.state.opportunities.firstWhere(
          (o) => o.ownerId == 'u-sita',
        );
        final noDue = await repo.create(
          Activity(
            id: uuidV4(),
            type: ActivityType.todo,
            relatedType: RelatedType.opportunity,
            relatedId: o.id,
            summary: 'Call back',
            ownerId: '',
            updatedAt: DateTime.utc(2026),
          ),
        );
        expect(
          noDue.errorOrNull,
          isA<ValidationFailure>().having((f) => f.field, 'f', 'dueAt'),
        );
        final call = (await repo.create(
          Activity(
            id: uuidV4(),
            type: ActivityType.call,
            relatedType: RelatedType.opportunity,
            relatedId: o.id,
            summary: 'Intro call',
            outcome: 'Interested',
            ownerId: '',
            updatedAt: DateTime.utc(2026),
          ),
        )).getOrThrow();
        expect(call.state, ActivityState.done);
        expect(call.ownerId, 'u-sita');
        final hist =
            (await h.container
                    .read(historyRepositoryProvider)
                    .forRecord(RelatedType.opportunity, o.id))
                .getOrThrow();
        expect(hist.first.text, 'Intro call — Interested');
      },
    );

    test('complete and reschedule respect conflicts', () async {
      final repo = h.container.read(activityRepositoryProvider);
      final a = h.store.state.activities.firstWhere(
        (a) =>
            a.ownerId == 'u-sita' &&
            a.type == ActivityType.todo &&
            a.state == ActivityState.planned,
      );
      expect(
        (await repo.complete(
          a.id,
          outcome: 'x',
          expectedUpdatedAt: DateTime.utc(1999),
        )).errorOrNull,
        const Failure.conflict(),
      );
      final moved = (await repo.reschedule(
        a.id,
        dueAt: h.store.clock.now().add(const Duration(days: 2)),
        expectedUpdatedAt: a.updatedAt,
      )).getOrThrow();
      expect(moved.state, ActivityState.planned);
      final done = (await repo.complete(
        a.id,
        outcome: 'Agreed',
        expectedUpdatedAt: moved.updatedAt,
      )).getOrThrow();
      expect(done.state, ActivityState.done);
      expect(done.outcome, 'Agreed');
    });

    test('list derives overdue from dueAt', () async {
      final repo = h.container.read(activityRepositoryProvider);
      final list = (await repo.list(const ActivityFilter(followUpsOnly: true)))
          .getOrThrow();
      final now = h.store.clock.now();
      for (final a in list.where((a) => a.state != ActivityState.done)) {
        expect(a.state == ActivityState.overdue, a.dueAt!.isBefore(now));
      }
    });
  });

  group('search (FR-MOB-003)', () {
    test('matches name, phone and email, grouped', () async {
      h.store.setCurrentUser('u-sita');
      final repo = h.container.read(searchRepositoryProvider);
      final byName = (await repo.search('himalayan')).getOrThrow();
      expect(
        byName.customers.map((c) => c.name),
        contains('Himalayan Traders'),
      );
      final contact = h.store.state.customers.firstWhere((c) => !c.isCompany);
      final byPhone = (await repo.search(contact.phone!.substring(5)))
          .getOrThrow();
      expect(byPhone.contacts.map((c) => c.id), contains(contact.id));
      final byEmail = (await repo.search(contact.email!)).getOrThrow();
      expect(byEmail.contacts.map((c) => c.id), contains(contact.id));
      expect((await repo.search('')).getOrThrow().isEmpty, isTrue);
    });
  });

  group('failure injection', () {
    test('airplane mode and forced failures', () async {
      h.store.setCurrentUser('u-sita');
      final repo = h.container.read(customerRepositoryProvider);
      h.store.airplaneMode = true;
      expect((await repo.list()).errorOrNull, const Failure.network());
      h.store.airplaneMode = false;
      h.store.forceNextFailure = const Failure.timeout();
      expect((await repo.list()).errorOrNull, const Failure.timeout());
      expect(h.store.forceNextFailure, isNull);
      expect((await repo.list()).isOk, isTrue);
    });
  });
}
