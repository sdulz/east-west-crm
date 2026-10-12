import 'dart:convert';

import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/features/pending/domain/pending_queue_repository.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'write_coordinator.g.dart';

/// What the UI gets back from a save (FR-MOB-013 / FR-MOB-015).
sealed class SaveOutcome<T> {
  const SaveOutcome();
}

/// The repository confirmed the write. Only now may the UI say "Saved".
final class SaveSuccess<T> extends SaveOutcome<T> {
  const SaveSuccess(this.value);
  final T value;
}

/// Transient failure; the write is in the encrypted queue.
final class SaveQueued<T> extends SaveOutcome<T> {
  const SaveQueued(this.write);
  final PendingWrite write;
}

/// Final failure (validation / permission / conflict / unknown). Never queued.
final class SaveRejected<T> extends SaveOutcome<T> {
  const SaveRejected(this.failure);
  final Failure failure;
}

class WriteCoordinator {
  WriteCoordinator(this._queue, this._now);
  final PendingQueueRepository _queue;
  final DateTime Function() _now;

  Future<SaveOutcome<T>> run<T>({
    required WriteOperation operation,
    required String targetId,
    required Map<String, dynamic> payload,
    required String label,
    required Future<Result<T, Failure>> Function() call,
  }) async {
    final r = await call();
    switch (r) {
      case Ok(:final value):
        return SaveSuccess(value);
      case Err(:final error) when error.isTransient:
        final w = PendingWrite(
          id: uuidV4(),
          operation: operation,
          payloadJson: jsonEncode(payload),
          targetId: targetId,
          createdAt: _now(),
          label: label,
        );
        await _queue.enqueue(w);
        return SaveQueued(w);
      case Err(:final error):
        return SaveRejected(error);
    }
  }
}

@riverpod
WriteCoordinator writeCoordinator(Ref ref) => WriteCoordinator(
  ref.watch(pendingQueueRepositoryProvider),
  ref.watch(clockProvider).now,
);
