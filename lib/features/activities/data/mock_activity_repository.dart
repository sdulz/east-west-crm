import 'package:field_crm/core/mock/mock_state.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/mock/mock_validation.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/domain/activity_repository.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';

class MockActivityRepository implements ActivityRepository {
  MockActivityRepository(this.store);
  final MockStore store;

  List<Activity> get _all => store.state.activities;

  @override
  Future<Result<List<ActivityTypeDef>, Failure>> types() =>
      store.call(() => store.state.activityTypes);

  @override
  Future<Result<List<Activity>, Failure>> list([
    ActivityFilter? filter,
  ]) => store.call(() {
    final f = filter ?? const ActivityFilter();
    final followUpTypes = store.state.activityTypes
        .where((t) => t.isFollowUp)
        .map((t) => t.type)
        .toSet();
    final now = store.clock.now();
    return store
        .visibleActivities()
        .map((a) => _withDerivedState(a, now))
        .where((a) => f.relatedType == null || a.relatedType == f.relatedType)
        .where((a) => f.relatedId == null || a.relatedId == f.relatedId)
        .where((a) => f.ownerId == null || a.ownerId == f.ownerId)
        .where((a) => f.state == null || a.state == f.state)
        .where((a) => f.followUpsOnly != true || followUpTypes.contains(a.type))
        .where(
          (a) => f.dueFrom == null || (a.dueAt?.isAfter(f.dueFrom!) ?? false),
        )
        .where((a) => f.dueTo == null || (a.dueAt?.isBefore(f.dueTo!) ?? false))
        .toList()
      ..sort(
        (a, b) => (a.dueAt ?? a.updatedAt).compareTo(b.dueAt ?? b.updatedAt),
      );
  });

  @override
  Future<Result<Activity, Failure>> getById(String id) =>
      store.call(() => _withDerivedState(_visible(id), store.clock.now()));

  @override
  Future<Result<Activity, Failure>> create(Activity a) => store.call(() {
    final me = store.currentUser;
    if (!me.permissions.canLogActivity) {
      throw const MockFailure(Failure.permissionDenied());
    }
    final existing = _all.where((x) => x.id == a.id).firstOrNull;
    if (existing != null) return existing;
    MockValidation.required(a.summary, 'summary', 'Summary');
    final isFollowUp = store.state.activityTypes.any(
      (t) => t.type == a.type && t.isFollowUp,
    );
    if (isFollowUp && a.dueAt == null) {
      throw const MockFailure(
        Failure.validation(
          'Follow-ups need a due date and time',
          field: 'dueAt',
        ),
      );
    }
    _checkRelated(a);
    final saved = a.copyWith(
      ownerId: a.ownerId.isEmpty ? me.id : a.ownerId,
      state: isFollowUp ? ActivityState.planned : ActivityState.done,
      updatedAt: store.clock.now(),
    );
    _all.add(saved);
    if (a.type == ActivityType.note) {
      for (final u in store.state.users) {
        if (saved.summary.contains('@${u.name}')) {
          store.notify(
            userId: u.id,
            kind: NotificationKind.mention,
            title: '${me.name} mentioned you',
            body: saved.summary,
            relatedType: saved.relatedType,
            relatedId: saved.relatedId,
          );
        }
      }
    }
    if (!isFollowUp) {
      _addHistory(
        saved,
        HistoryEntry(
          id: 'h-${saved.id}',
          kind: a.type == ActivityType.note
              ? HistoryKind.note
              : HistoryKind.activity,
          at: saved.updatedAt,
          actorName: me.name,
          text:
              '${saved.summary}'
              '${saved.outcome == null ? '' : ' — ${saved.outcome}'}',
        ),
      );
    }
    return saved;
  }, write: true);

  @override
  Future<Result<Activity, Failure>> complete(
    String id, {
    required String outcome,
    required DateTime expectedUpdatedAt,
  }) => store.call(() {
    final me = store.currentUser;
    final current = _visible(id);
    MockValidation.conflict(current.updatedAt, expectedUpdatedAt);
    MockValidation.required(outcome, 'outcome', 'Outcome');
    final saved = current.copyWith(
      state: ActivityState.done,
      outcome: outcome,
      updatedAt: store.clock.now(),
    );
    _all[_all.indexWhere((x) => x.id == id)] = saved;
    _addHistory(
      saved,
      HistoryEntry(
        id: 'h-${saved.id}-done',
        kind: HistoryKind.activity,
        at: saved.updatedAt,
        actorName: me.name,
        text: '${saved.summary} — $outcome',
      ),
    );
    return saved;
  }, write: true);

  @override
  Future<Result<Activity, Failure>> reschedule(
    String id, {
    required DateTime dueAt,
    required DateTime expectedUpdatedAt,
  }) => store.call(() {
    final current = _visible(id);
    MockValidation.conflict(current.updatedAt, expectedUpdatedAt);
    final saved = current.copyWith(
      dueAt: dueAt.toUtc(),
      state: ActivityState.planned,
      updatedAt: store.clock.now(),
    );
    _all[_all.indexWhere((x) => x.id == id)] = saved;
    return saved;
  }, write: true);

  Activity _visible(String id) {
    final a = _all.where((x) => x.id == id).firstOrNull;
    if (a == null) throw const MockFailure(Failure.unknown('Not found'));
    if (!store.canSeeActivity(a)) {
      throw const MockFailure(Failure.permissionDenied());
    }
    return a;
  }

  /// `overdue` is derived, never stored.
  Activity _withDerivedState(Activity a, DateTime now) {
    if (a.state == ActivityState.done) return a;
    final due = a.dueAt;
    if (due != null && due.isBefore(now)) {
      return a.copyWith(state: ActivityState.overdue);
    }
    return a.copyWith(state: ActivityState.planned);
  }

  void _checkRelated(Activity a) {
    final ok = switch (a.relatedType) {
      RelatedType.customer => store.state.customers.any(
        (c) => c.id == a.relatedId,
      ),
      RelatedType.opportunity => store.state.opportunities.any(
        (o) => o.id == a.relatedId,
      ),
    };
    if (!ok) {
      throw const MockFailure(
        Failure.validation('Related record does not exist', field: 'relatedId'),
      );
    }
  }

  void _addHistory(Activity a, HistoryEntry e) => store.state.history
      .putIfAbsent(MockState.historyKey(a.relatedType, a.relatedId), () => [])
      .add(e);
}
