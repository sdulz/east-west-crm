import 'package:drift/drift.dart';
import 'package:field_crm/core/storage/app_database.dart';
import 'package:field_crm/features/pending/domain/pending_queue_repository.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';

class DriftPendingQueueRepository implements PendingQueueRepository {
  DriftPendingQueueRepository(this.db);
  final AppDatabase db;

  @override
  Stream<List<PendingWrite>> watchAll() =>
      _ordered().watch().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<List<PendingWrite>> all() async =>
      (await _ordered().get()).map(_toDomain).toList();

  @override
  Future<void> enqueue(PendingWrite w) =>
      db.into(db.pendingWrites).insertOnConflictUpdate(_toRow(w));

  @override
  Future<void> update(PendingWrite w) =>
      db.into(db.pendingWrites).insertOnConflictUpdate(_toRow(w));

  @override
  Future<void> remove(String id) =>
      (db.delete(db.pendingWrites)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> clear() => db.delete(db.pendingWrites).go();

  SimpleSelectStatement<$PendingWritesTable, PendingWriteRow> _ordered() =>
      db.select(db.pendingWrites)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  PendingWrite _toDomain(PendingWriteRow r) => PendingWrite(
    id: r.id,
    operation: WriteOperation.values.byName(r.operation),
    payloadJson: r.payloadJson,
    targetId: r.targetId,
    status: PendingStatus.values.byName(r.status),
    attempts: r.attempts,
    lastError: r.lastError,
    createdAt: r.createdAt.toUtc(),
    label: r.label,
  );

  PendingWritesCompanion _toRow(PendingWrite w) =>
      PendingWritesCompanion.insert(
        id: w.id,
        operation: w.operation.name,
        payloadJson: w.payloadJson,
        targetId: w.targetId,
        status: w.status.name,
        attempts: Value(w.attempts),
        lastError: Value(w.lastError),
        createdAt: w.createdAt.toUtc(),
        label: Value(w.label),
      );
}
