import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:field_crm/app/app.dart';
import 'package:field_crm/app/env.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/logging/app_logger.dart';
import 'package:field_crm/core/mock/mock_seed_loader.dart';
import 'package:field_crm/core/mock/mock_state.dart';
import 'package:field_crm/core/mock/mock_state_store.dart';
import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/storage/app_database.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;

// Latency defaults equal the env defaults on purpose; both come from config.
// ignore_for_file: avoid_redundant_argument_values

const _log = AppLogger('bootstrap');

/// Shared entry point for every flavor (main_dev / main_uat / main_prod).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final secure = FlutterSecureStore();
  final db = AppDatabase.open(
    name: 'field_crm_${AppEnv.flavorName}',
    key: await _dbKey(secure),
  );
  final store = await buildMockStore(
    seedJson: await rootBundle.loadString('assets/seed/seed.json'),
    stateStore: DriftMockStateStore(db),
  );

  final overrides = [
    secureStoreProvider.overrideWithValue(secure),
    appDatabaseProvider.overrideWithValue(db),
    mockStoreProvider.overrideWithValue(store),
  ];

  Future<void> run() async {
    final container = ProviderContainer(overrides: overrides);
    await container.read(reminderSchedulerProvider).initialize();
    await container.read(pushNotificationServiceProvider).initialize();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const FieldCrmApp(),
      ),
    );
  }

  if (AppEnv.sentryDsn.isEmpty) {
    await run();
    return;
  }
  await SentryFlutter.init((o) {
    o
      ..dsn = AppEnv.sentryDsn
      ..environment = AppEnv.flavorName
      ..sendDefaultPii = false
      ..beforeSend = _scrub
      ..beforeBreadcrumb = (crumb, hint) =>
          crumb?..message = AppLogger.redact(crumb.message ?? '');
  }, appRunner: run);
}

/// Builds the mock from the persisted snapshot, or from the seed asset.
Future<MockStore> buildMockStore({
  required String seedJson,
  required MockStateStore stateStore,
  Clock clock = const Clock(),
  Random? random,
}) async {
  const loader = MockSeedLoader();
  MockState reseed() => loader.fromJsonString(seedJson, now: clock.now());
  MockState initial;
  try {
    final saved = await stateStore.load();
    initial = saved == null
        ? reseed()
        : MockState.fromJson(jsonDecode(saved) as Map<String, dynamic>);
  } on Object catch (e) {
    _log.warn('snapshot unreadable, reseeding: $e');
    initial = reseed();
  }
  return MockStore(
    initial: initial,
    clock: clock,
    stateStore: stateStore,
    reseed: reseed,
    minLatency: const Duration(milliseconds: AppEnv.mockMinLatencyMs),
    maxLatency: const Duration(milliseconds: AppEnv.mockMaxLatencyMs),
    random: random,
  );
}

/// 256-bit DB key, generated once and kept only in secure storage.
Future<String> _dbKey(SecureStore secure) async {
  final existing = await secure.read(SecureKeys.dbKey);
  if (existing != null) return existing;
  final rng = Random.secure();
  final key = List.generate(
    32,
    (_) => rng.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  await secure.write(SecureKeys.dbKey, key);
  return key;
}

/// Strip anything that could carry PII before it leaves the device.
FutureOr<SentryEvent?> _scrub(SentryEvent event, Hint hint) {
  event.user = null;
  final msg = event.message;
  if (msg != null) msg.formatted = AppLogger.redact(msg.formatted);
  for (final b in event.breadcrumbs ?? const <Breadcrumb>[]) {
    b.message = AppLogger.redact(b.message ?? '');
  }
  return event;
}
