import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:field_crm/app/env.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/storage/app_database.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/features/pending/application/pending_queue_controller.dart';
import 'package:field_crm/features/pending/application/reconnect_retry.dart';
import 'package:field_crm/features/pending/data/drift_pending_queue_repository.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late TestHarness h;
  late DriftPendingQueueRepository repo;

  setUp(() async {
    h = await TestHarness.create(now: DateTime.utc(2026, 10, 12, 9));
    repo = DriftPendingQueueRepository(h.db);
    h.store.setCurrentUser('u-sita');
    // Riverpod 3 pauses providers nobody listens to; the app always has a
    // listener (badges), tests need one explicitly.
    final sub = h.container.listen(pendingQueueControllerProvider, (_, _) {});
    addTearDown(sub.close);
  });
  tearDown(() => h.dispose());

  PendingWrite write({
    DateTime? createdAt,
    WriteOperation op = WriteOperation.customerUpdate,
    Map<String, dynamic>? payload,
    String target = 'c-001',
  }) => PendingWrite(
    id: uuidV4(),
    operation: op,
    payloadJson: jsonEncode(payload ?? {}),
    targetId: target,
    createdAt: createdAt ?? h.store.clock.now(),
    label: 'test',
  );

  test('encrypted drift queue round-trips a write', () async {
    if (Platform.isAndroid || Platform.isIOS) {
      expect(
        h.db.customSelect('pragma cipher_version').get(),
        completion(isNotEmpty),
      );
    }
    final w = write();
    await repo.enqueue(w);
    final all = await repo.all();
    expect(all.single.id, w.id);
    expect(all.single.status, PendingStatus.pending);
    await repo.remove(w.id);
    expect(await repo.all(), isEmpty);
  });

  test('retry: confirmed write is removed and lists refresh', () async {
    final c = h.store.state.customers.first;
    await repo.enqueue(
      write(
        payload: {
          'customer': c.copyWith(name: 'Renamed').toJson(),
          'expectedUpdatedAt': c.updatedAt.toIso8601String(),
        },
      ),
    );
    final tick = h.container.read(refreshTickProvider);
    final ok = await h.container
        .read(pendingQueueControllerProvider.notifier)
        .retry((await repo.all()).single.id);
    expect(ok, isTrue);
    expect(await repo.all(), isEmpty);
    expect(h.container.read(refreshTickProvider), tick + 1);
    expect(h.store.state.customers.first.name, 'Renamed');
  });

  test('retry: transient failure stays pending with attempts+1', () async {
    final c = h.store.state.customers.first;
    await repo.enqueue(
      write(
        payload: {
          'customer': c.toJson(),
          'expectedUpdatedAt': c.updatedAt.toIso8601String(),
        },
      ),
    );
    h.store.airplaneMode = true;
    final id = (await repo.all()).single.id;
    final ok = await h.container
        .read(pendingQueueControllerProvider.notifier)
        .retry(id);
    expect(ok, isFalse);
    final w = (await repo.all()).single;
    expect(w.status, PendingStatus.pending);
    expect(w.attempts, 1);
    expect(w.lastError, 'network');
  });

  test('retry: final failure (conflict) marks the item Failed', () async {
    final c = h.store.state.customers.first;
    await repo.enqueue(
      write(
        payload: {
          'customer': c.toJson(),
          'expectedUpdatedAt': DateTime.utc(2000).toIso8601String(),
        },
      ),
    );
    final id = (await repo.all()).single.id;
    await h.container.read(pendingQueueControllerProvider.notifier).retry(id);
    final w = (await repo.all()).single;
    expect(w.status, PendingStatus.failed);
    expect(w.lastError, 'conflict');
  });

  test('items older than max age become Failed(expired)', () async {
    await repo.enqueue(
      write(
        createdAt: h.store.clock.now().subtract(
          const Duration(days: AppEnv.pendingMaxAgeDays + 1),
        ),
      ),
    );
    final list = await h.container.read(pendingQueueControllerProvider.future);
    expect(list.single.status, PendingStatus.failed);
    expect(list.single.lastError, 'expired');
  });

  test('pendingByTarget: failed wins over pending for badges', () async {
    await repo.enqueue(write(target: 'x'));
    await repo.enqueue(
      write(target: 'x').copyWith(status: PendingStatus.failed),
    );
    // Drift emits per table change; wait for the second row to arrive.
    while ((h.container.read(pendingQueueControllerProvider).value?.length ??
            0) <
        2) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(
      h.container.read(pendingByTargetProvider)['x'],
      PendingStatus.failed,
    );
  });

  test('backoff is exponential and capped at 60s', () {
    expect(ReconnectRetry.backoff(0), const Duration(seconds: 1));
    expect(ReconnectRetry.backoff(3), const Duration(seconds: 8));
    expect(ReconnectRetry.backoff(10), const Duration(seconds: 60));
  });

  test('a fresh container can open its own encrypted memory DB', () async {
    final db = AppDatabase(
      NativeDatabase.memory(setup: (d) => AppDatabase.applyKey(d, 'k')),
    );
    addTearDown(db.close);
    final c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    expect(await c.read(pendingQueueRepositoryProvider).all(), isEmpty);
    expect(const Failure.network().isTransient, isTrue);
  });
}
