import 'package:field_crm/core/mock/mock_state.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/mock/mock_validation.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/opportunities/domain/opportunity_repository.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';

class MockOpportunityRepository implements OpportunityRepository {
  MockOpportunityRepository(this.store);
  final MockStore store;

  List<Opportunity> get _all => store.state.opportunities;

  @override
  Future<Result<List<Opportunity>, Failure>> list({String? customerId}) =>
      store.call(() {
        var items = store.visibleOpportunities();
        if (customerId != null) {
          items = items.where((o) => o.customerId == customerId);
        }
        return items.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      });

  @override
  Future<Result<Opportunity, Failure>> getById(String id) =>
      store.call(() => _visible(id));

  @override
  Future<Result<Opportunity, Failure>> create(Opportunity o) => store.call(() {
    final me = store.currentUser;
    if (!me.permissions.canCreateOpportunity) {
      throw const MockFailure(Failure.permissionDenied());
    }
    final existing = _all.where((x) => x.id == o.id).firstOrNull;
    if (existing != null) return existing;
    _validate(o);
    final saved = o.copyWith(
      ownerId: o.ownerId.isEmpty ? me.id : o.ownerId,
      teamId: me.teamId,
      stageId: o.stageId.isEmpty ? _firstStage().id : o.stageId,
      updatedAt: store.clock.now(),
    );
    _all.add(saved);
    return saved;
  }, write: true);

  @override
  Future<Result<Opportunity, Failure>> update(
    Opportunity o, {
    required DateTime expectedUpdatedAt,
  }) => store.call(() {
    if (!store.currentUser.permissions.canEditOpportunity) {
      throw const MockFailure(Failure.permissionDenied());
    }
    final current = _visible(o.id);
    MockValidation.conflict(current.updatedAt, expectedUpdatedAt);
    _validate(o);
    // Stage and owner have their own endpoints with their own rules.
    final saved = o.copyWith(
      stageId: current.stageId,
      ownerId: current.ownerId,
      teamId: current.teamId,
      updatedAt: store.clock.now(),
    );
    _all[_all.indexWhere((x) => x.id == o.id)] = saved;
    return saved;
  }, write: true);

  @override
  Future<Result<Opportunity, Failure>> changeStage(
    String id, {
    required String toStageId,
    required DateTime expectedUpdatedAt,
  }) => store.call(() {
    final me = store.currentUser;
    if (!me.permissions.canChangeStage) {
      throw const MockFailure(Failure.permissionDenied());
    }
    final current = _visible(id);
    MockValidation.conflict(current.updatedAt, expectedUpdatedAt);
    final from = _stage(current.stageId);
    final to = _stage(toStageId);
    if (!from.canMoveTo(to.id)) {
      throw MockFailure(
        Failure.validation(
          'Moving from ${from.name} to ${to.name} is not allowed',
          field: 'stageId',
        ),
      );
    }
    if (from.id == to.id) return current;
    final saved = current.copyWith(
      stageId: to.id,
      probability: to.isWon ? 100 : current.probability,
      updatedAt: store.clock.now(),
    );
    _all[_all.indexWhere((x) => x.id == id)] = saved;
    _addHistory(
      id,
      HistoryEntry(
        id: 'h-${store.clock.now().microsecondsSinceEpoch}',
        kind: HistoryKind.stageChange,
        at: saved.updatedAt,
        actorName: me.name,
        from: from.name,
        to: to.name,
      ),
    );
    return saved;
  }, write: true);

  @override
  Future<Result<Opportunity, Failure>> reassign(
    String id, {
    required String newOwnerId,
    required DateTime expectedUpdatedAt,
  }) => store.call(() {
    final me = store.currentUser;
    if (!me.permissions.canReassign) {
      throw const MockFailure(Failure.permissionDenied());
    }
    final current = _visible(id);
    MockValidation.conflict(current.updatedAt, expectedUpdatedAt);
    final newOwner = store.state.users
        .where((u) => u.id == newOwnerId && u.teamId == me.teamId)
        .firstOrNull;
    if (newOwner == null || !newOwner.isActive) {
      throw const MockFailure(
        Failure.validation(
          'Owner must be an active member of your team',
          field: 'ownerId',
        ),
      );
    }
    final oldOwner = store.state.users
        .where((u) => u.id == current.ownerId)
        .firstOrNull;
    final saved = current.copyWith(
      ownerId: newOwner.id,
      updatedAt: store.clock.now(),
    );
    _all[_all.indexWhere((x) => x.id == id)] = saved;
    _addHistory(
      id,
      HistoryEntry(
        id: 'h-${store.clock.now().microsecondsSinceEpoch}',
        kind: HistoryKind.ownerChange,
        at: saved.updatedAt,
        actorName: me.name,
        from: oldOwner?.name ?? current.ownerId,
        to: newOwner.name,
      ),
    );
    return saved;
  }, write: true);

  Opportunity _visible(String id) {
    final o = _all.where((x) => x.id == id).firstOrNull;
    if (o == null) throw const MockFailure(Failure.unknown('Not found'));
    if (!store.canSeeOpportunity(o)) {
      throw const MockFailure(Failure.permissionDenied());
    }
    return o;
  }

  PipelineStage _stage(String id) {
    final s = store.state.stages.where((s) => s.id == id).firstOrNull;
    if (s == null) {
      throw MockFailure(
        Failure.validation('Unknown stage $id', field: 'stageId'),
      );
    }
    return s;
  }

  PipelineStage _firstStage() => ([
    ...store.state.stages,
  ]..sort((a, b) => a.sequence.compareTo(b.sequence))).first;

  void _validate(Opportunity o) {
    MockValidation.required(o.title, 'title', 'Title');
    if (!store.state.customers.any((c) => c.id == o.customerId)) {
      throw const MockFailure(
        Failure.validation('Customer is required', field: 'customerId'),
      );
    }
    MockValidation.range(
      o.expectedRevenue,
      0,
      1e12,
      'expectedRevenue',
      'Expected revenue',
    );
    MockValidation.range(o.probability, 0, 100, 'probability', 'Probability');
  }

  void _addHistory(String id, HistoryEntry e) => store.state.history
      .putIfAbsent(MockState.historyKey(RelatedType.opportunity, id), () => [])
      .add(e);
}
