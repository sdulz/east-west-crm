import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:field_crm/app/app.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/connectivity/connectivity_service.dart';
import 'package:field_crm/core/mock/mock_seed_loader.dart';
import 'package:field_crm/core/mock/mock_state.dart';
import 'package:field_crm/core/mock/mock_state_store.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/notifications/reminder_scheduler.dart';
import 'package:field_crm/core/storage/app_database.dart';
import 'package:field_crm/core/storage/biometric_auth.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:field_crm/features/pending/domain/pending_queue_repository.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

/// Everything a widget / integration test needs to run the real app against
/// the mock with zero latency and in-memory storage.
class TestHarness {
  TestHarness._({
    required this.store,
    required this.db,
    required this.secure,
    required this.reminders,
    required this.connectivity,
    required this.container,
  });

  static String? _seedCache;

  static Future<TestHarness> create({
    DateTime? now,
    Duration latency = Duration.zero,
    bool encrypted = true,
  }) async {
    tzdata.initializeTimeZones();
    // Synchronous on purpose: real async I/O never completes inside the
    // fake-async zone of testWidgets.
    final seed = _seedCache ??= File('assets/seed/seed.json')
        .readAsStringSync();
    final clock = FixedClock(now ?? DateTime.now().toUtc());
    const loader = MockSeedLoader();
    MockState reseed() => loader.fromJsonString(seed, now: clock.now());
    final store = MockStore(
      initial: reseed(),
      clock: clock,
      stateStore: InMemoryMockStateStore(),
      reseed: reseed,
      minLatency: latency,
      maxLatency: latency,
      random: Random(1),
    );
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: encrypted ? (db) => AppDatabase.applyKey(db, 'test-key') : null,
      ),
    );
    final secure = InMemorySecureStore();
    final reminders = FakeReminderScheduler();
    final connectivity = FakeConnectivityService();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        secureStoreProvider.overrideWithValue(secure),
        appDatabaseProvider.overrideWithValue(db),
        mockStoreProvider.overrideWithValue(store),
        reminderSchedulerProvider.overrideWithValue(reminders),
        connectivityServiceProvider.overrideWithValue(connectivity),
        biometricAuthProvider.overrideWithValue(
          FakeBiometricAuth(available: false),
        ),
      ],
    );
    return TestHarness._(
      store: store,
      db: db,
      secure: secure,
      reminders: reminders,
      connectivity: connectivity,
      container: container,
    );
  }

  final MockStore store;
  final AppDatabase db;
  final InMemorySecureStore secure;
  final FakeReminderScheduler reminders;
  final FakeConnectivityService connectivity;
  final ProviderContainer container;

  Widget get app => UncontrolledProviderScope(
    container: container,
    child: const FieldCrmApp(),
  );

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

class FakeConnectivityService implements ConnectivityService {
  final controller = StreamController<bool>.broadcast();
  bool online = true;

  @override
  Stream<bool> get onlineChanges => controller.stream;

  @override
  Future<bool> isOnline() async => online;

  void set(bool value) {
    online = value;
    controller.add(value);
  }
}

/// Pumps the app on a phone-sized surface (the default 800x600 test view
/// pushes sheet items and form buttons off-screen).
Future<void> pumpApp(WidgetTester tester, TestHarness h) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(h.app);
}

/// Pumps until [finder] matches or [timeout] elapses (mock calls are async).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> login(
  WidgetTester tester, {
  String email = 'sita@fieldcrm.test',
  String password = 'password',
}) async {
  await pumpUntilFound(tester, find.byKey(const Key('login_email')));
  await tester.enterText(find.byKey(const Key('login_email')), email);
  await tester.enterText(find.byKey(const Key('login_password')), password);
  await tester.tap(find.byKey(const Key('login_submit')));
  await tester.pump();
}

/// Flushes in-flight mock calls and disposes the tree so no timers remain.
Future<void> finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// In-memory queue for unit tests of the write path.
class InMemoryPendingQueue implements PendingQueueRepository {
  final List<PendingWrite> items = [];
  final _controller = StreamController<List<PendingWrite>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(items));

  @override
  Stream<List<PendingWrite>> watchAll() async* {
    yield List.unmodifiable(items);
    yield* _controller.stream;
  }

  @override
  Future<List<PendingWrite>> all() async => List.unmodifiable(items);

  @override
  Future<void> enqueue(PendingWrite write) async {
    items.add(write);
    _emit();
  }

  @override
  Future<void> update(PendingWrite write) async {
    final i = items.indexWhere((w) => w.id == write.id);
    if (i >= 0) items[i] = write;
    _emit();
  }

  @override
  Future<void> remove(String id) async {
    items.removeWhere((w) => w.id == id);
    _emit();
  }

  @override
  Future<void> clear() async {
    items.clear();
    _emit();
  }
}
