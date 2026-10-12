import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'opportunity_controllers.g.dart';

/// FR-MOB-005. Kept alive: tab switches must not refetch.
@Riverpod(keepAlive: true)
Future<List<Opportunity>> opportunityList(Ref ref, {String? customerId}) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref
      .watch(opportunityRepositoryProvider)
      .list(customerId: customerId)
      .orThrow;
}

@Riverpod(keepAlive: true)
Future<Opportunity> opportunityDetail(Ref ref, String id) {
  ref.watch(refreshTickProvider);
  return ref.watch(opportunityRepositoryProvider).getById(id).orThrow;
}

@Riverpod(keepAlive: true)
class OpportunitySaver extends _$OpportunitySaver {
  @override
  void build() {}

  WriteCoordinator get _wc => ref.read(writeCoordinatorProvider);

  void _confirmed(SaveOutcome<Object?> o) {
    if (o is SaveSuccess) ref.read(refreshTickProvider.notifier).bump();
  }

  Future<SaveOutcome<Opportunity>> save(
    Opportunity o, {
    required bool isNew,
    DateTime? expectedUpdatedAt,
  }) async {
    final repo = ref.read(opportunityRepositoryProvider);
    final out = await _wc.run<Opportunity>(
      operation: isNew
          ? WriteOperation.opportunityCreate
          : WriteOperation.opportunityUpdate,
      targetId: o.id,
      label: isNew ? 'New opportunity' : 'Opportunity update',
      payload: {
        'opportunity': o.toJson(),
        'expectedUpdatedAt': expectedUpdatedAt?.toIso8601String(),
      },
      call: () => isNew
          ? repo.create(o)
          : repo.update(o, expectedUpdatedAt: expectedUpdatedAt!),
    );
    _confirmed(out);
    return out;
  }

  /// FR-MOB-008.
  Future<SaveOutcome<Opportunity>> changeStage(
    Opportunity o, {
    required String toStageId,
  }) async {
    final out = await _wc.run<Opportunity>(
      operation: WriteOperation.opportunityStageChange,
      targetId: o.id,
      label: 'Stage change',
      payload: {
        'toStageId': toStageId,
        'expectedUpdatedAt': o.updatedAt.toIso8601String(),
      },
      call: () => ref
          .read(opportunityRepositoryProvider)
          .changeStage(
            o.id,
            toStageId: toStageId,
            expectedUpdatedAt: o.updatedAt,
          ),
    );
    _confirmed(out);
    return out;
  }

  /// FR-MOB-009.
  Future<SaveOutcome<Opportunity>> reassign(
    Opportunity o, {
    required String newOwnerId,
  }) async {
    final out = await _wc.run<Opportunity>(
      operation: WriteOperation.opportunityReassign,
      targetId: o.id,
      label: 'Handover',
      payload: {
        'newOwnerId': newOwnerId,
        'expectedUpdatedAt': o.updatedAt.toIso8601String(),
      },
      call: () => ref
          .read(opportunityRepositoryProvider)
          .reassign(
            o.id,
            newOwnerId: newOwnerId,
            expectedUpdatedAt: o.updatedAt,
          ),
    );
    _confirmed(out);
    return out;
  }
}
