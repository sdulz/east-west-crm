import 'package:field_crm/features/pending/domain/pending_write.dart';

/// Local, encrypted queue of writes that failed transiently.
abstract interface class PendingQueueRepository {
  Stream<List<PendingWrite>> watchAll();
  Future<List<PendingWrite>> all();
  Future<void> enqueue(PendingWrite write);
  Future<void> update(PendingWrite write);
  Future<void> remove(String id);
  Future<void> clear();
}
