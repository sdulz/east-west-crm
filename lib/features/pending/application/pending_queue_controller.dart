import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/env.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/pending/application/pending_replayer.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';

/// FR-MOB-013. Streams the encrypted queue and runs retries / discards.
class PendingQueueController extends StreamNotifier<List<PendingWrite>> {
  @override
  Stream<List<PendingWrite>> build() =>
      ref.watch(pendingQueueRepositoryProvider).watchAll().asyncMap(_expire);

  Duration get maxAge => const Duration(days: AppEnv.pendingMaxAgeDays);

  /// Items older than [maxAge] become Failed (never silently dropped).
  Future<List<PendingWrite>> _expire(List<PendingWrite> items) async {
    final now = ref.read(clockProvider).now();
    final repo = ref.read(pendingQueueRepositoryProvider);
    final out = <PendingWrite>[];
    for (final w in items) {
      if (w.status == PendingStatus.pending &&
          now.difference(w.createdAt) > maxAge) {
        final expired = w.copyWith(
          status: PendingStatus.failed,
          lastError: 'expired',
        );
        await repo.update(expired);
        out.add(expired);
      } else {
        out.add(w);
      }
    }
    return out;
  }

  /// Retries one item. Returns true when the repository confirmed it.
  Future<bool> retry(String id) async {
    final repo = ref.read(pendingQueueRepositoryProvider);
    final w = (await repo.all()).where((w) => w.id == id).firstOrNull;
    if (w == null) return false;
    final r = await ref.read(pendingReplayerProvider).replay(w);
    switch (r) {
      case Ok():
        await repo.remove(id);
        ref.read(refreshTickProvider.notifier).bump();
        return true;
      case Err(:final error):
        await repo.update(
          w.copyWith(
            attempts: w.attempts + 1,
            lastError: _describe(error),
            // A final failure cannot succeed by retrying the same payload.
            status: error.isTransient
                ? PendingStatus.pending
                : PendingStatus.failed,
          ),
        );
        return false;
    }
  }

  /// One pass over everything pending; no loops.
  Future<int> retryAll({bool includeFailed = true}) async {
    final items = await ref.read(pendingQueueRepositoryProvider).all();
    var ok = 0;
    for (final w in items) {
      if (!includeFailed && w.status == PendingStatus.failed) continue;
      if (await retry(w.id)) ok++;
    }
    return ok;
  }

  Future<void> discard(String id) =>
      ref.read(pendingQueueRepositoryProvider).remove(id);

  static String _describe(Failure f) => switch (f) {
    NetworkFailure() => 'network',
    TimeoutFailure() => 'timeout',
    PermissionDeniedFailure() => 'permission denied',
    ValidationFailure(:final message) => message,
    ConflictFailure() => 'conflict',
    UnknownFailure(:final message) => message ?? 'unknown',
  };
}

final pendingQueueControllerProvider =
    StreamNotifierProvider<PendingQueueController, List<PendingWrite>>(
  PendingQueueController.new,
);

/// targetId -> status, for badges in lists and detail screens.
final pendingByTargetProvider = Provider<Map<String, PendingStatus>>((ref) {
  final items = ref.watch(pendingQueueControllerProvider).valueOrNull ?? const [];
  final map = <String, PendingStatus>{};
  for (final w in items) {
    // Failed wins over pending so the worse state is visible.
    if (map[w.targetId] != PendingStatus.failed) map[w.targetId] = w.status;
  }
  return map;
});

final pendingCountProvider = Provider<int>((ref) =>
    ref.watch(pendingQueueControllerProvider).valueOrNull?.length ?? 0);
