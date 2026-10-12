import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'activity_controllers.g.dart';

@Riverpod(keepAlive: true)
Future<List<ActivityTypeDef>> activityTypes(Ref ref) =>
    ref.watch(activityRepositoryProvider).types().orThrow;

/// FR-MOB-006 / FR-MOB-007 lists.
@riverpod
Future<List<Activity>> activityList(Ref ref, ActivityFilter filter) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(activityRepositoryProvider).list(filter).orThrow;
}

/// The current user's open follow-ups.
@riverpod
Future<List<Activity>> myFollowUps(Ref ref) {
  final me = ref.watch(currentUserProvider);
  return ref.watch(
    activityListProvider(ActivityFilter(ownerId: me?.id, followUpsOnly: true))
        .future,
  );
}

@riverpod
class ActivitySaver extends _$ActivitySaver {
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
