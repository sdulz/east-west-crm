import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';

final _opportunityListFamily =
    FutureProvider.family<List<Opportunity>, String?>((ref, customerId) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref
      .watch(opportunityRepositoryProvider)
      .list(customerId: customerId)
      .orThrow;
});

FutureProvider<List<Opportunity>> opportunityListProvider({String? customerId}) =>
    _opportunityListFamily(customerId);

final opportunityDetailProvider =
    FutureProvider.family<Opportunity, String>((ref, id) {
  ref.watch(refreshTickProvider);
  return ref.watch(opportunityRepositoryProvider).getById(id).orThrow;
});

class OpportunitySaver extends Notifier<void> {
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

final opportunitySaverProvider =
    NotifierProvider<OpportunitySaver, void>(OpportunitySaver.new);
