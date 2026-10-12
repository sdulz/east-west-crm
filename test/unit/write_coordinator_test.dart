import 'dart:convert';

import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late InMemoryPendingQueue queue;
  late WriteCoordinator wc;
  final now = DateTime.utc(2026, 10, 12);

  setUp(() {
    queue = InMemoryPendingQueue();
    wc = WriteCoordinator(queue, () => now);
  });

  Future<SaveOutcome<String>> run(Result<String, Failure> r) => wc.run(
    operation: WriteOperation.customerCreate,
    targetId: 'c-1',
    payload: {'customer': 'json'},
    label: 'New customer',
    call: () async => r,
  );

  test('success is only reported after the repository confirms', () async {
    final out = await run(const Ok('saved'));
    expect(out, isA<SaveSuccess<String>>());
    expect(queue.items, isEmpty);
  });

  test('FR-MOB-013 network failure is queued with the payload', () async {
    final out = await run(const Err(Failure.network()));
    expect(out, isA<SaveQueued<String>>());
    final w = queue.items.single;
    expect(w.operation, WriteOperation.customerCreate);
    expect(w.targetId, 'c-1');
    expect(w.status, PendingStatus.pending);
    expect(w.createdAt, now);
    expect(jsonDecode(w.payloadJson), {'customer': 'json'});
  });

  test('timeout is queued too', () async {
    expect(await run(const Err(Failure.timeout())), isA<SaveQueued<String>>());
    expect(queue.items.length, 1);
  });

  test('validation / permission / conflict are final, never queued', () async {
    for (final f in const [
      Failure.validation('Name is required'),
      Failure.permissionDenied(),
      Failure.conflict(),
      Failure.unknown(),
    ]) {
      final out = await run(Err(f));
      expect(out, isA<SaveRejected<String>>());
      expect((out as SaveRejected<String>).failure, f);
    }
    expect(queue.items, isEmpty);
  });
}
