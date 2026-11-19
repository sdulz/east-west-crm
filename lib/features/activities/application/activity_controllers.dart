import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';

final activityTypesProvider = FutureProvider<List<ActivityTypeDef>>((ref) =>
    ref.watch(activityRepositoryProvider).types().orThrow);

final activityListProvider =
    FutureProvider.family<List<Activity>, ActivityFilter>((ref, filter) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(activityRepositoryProvider).list(filter).orThrow;
});

final myFollowUpsProvider = FutureProvider<List<Activity>>((ref) {
  final me = ref.watch(currentUserProvider);
  return ref.watch(
    activityListProvider(ActivityFilter(ownerId: me?.id, followUpsOnly: true))
        .future,
  );
});

class ActivitySaver extends Notifier<void> {
  @override
  void build() {}

  WriteCoordinator get _wc => ref.read(writeCoordinatorProvider);

  void _confirmed(SaveOutcome<Object?> o) {
    if (o is SaveSuccess) ref.read(refreshTickProvider.notifier).bump();
  }

  Future<SaveOutcome<Activity>> create(Activity a) async {
    final out = await _wc.run<Activity>(
      operation: WriteOperation.activityCreate,
      targetId: a.id,
      label: a.type == ActivityType.todo ? 'New follow-up' : 'Log interaction',
      payload: {'activity': a.toJson()},
      call: () => ref.read(activityRepositoryProvider).create(a),
    );
    _confirmed(out);
    return out;
  }

  Future<SaveOutcome<Activity>> complete(
    Activity a, {
    required String outcome,
  }) async {
    final out = await _wc.run<Activity>(
      operation: WriteOperation.activityComplete,
      targetId: a.id,
      label: 'Complete follow-up',
      payload: {
        'outcome': outcome,
        'expectedUpdatedAt': a.updatedAt.toIso8601String(),
      },
      call: () => ref
          .read(activityRepositoryProvider)
          .complete(a.id, outcome: outcome, expectedUpdatedAt: a.updatedAt),
    );
    _confirmed(out);
    return out;
  }

  Future<SaveOutcome<Activity>> reschedule(
    Activity a, {
    required DateTime dueAt,
  }) async {
    final out = await _wc.run<Activity>(
      operation: WriteOperation.activityReschedule,
      targetId: a.id,
      label: 'Reschedule follow-up',
      payload: {
        'dueAt': dueAt.toUtc().toIso8601String(),
        'expectedUpdatedAt': a.updatedAt.toIso8601String(),
      },
      call: () => ref
          .read(activityRepositoryProvider)
          .reschedule(a.id, dueAt: dueAt, expectedUpdatedAt: a.updatedAt),
    );
    _confirmed(out);
    return out;
  }
}

final activitySaverProvider =
    NotifierProvider<ActivitySaver, void>(ActivitySaver.new);
