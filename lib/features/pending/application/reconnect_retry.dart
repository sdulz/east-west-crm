import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/logging/app_logger.dart';
import 'package:field_crm/features/pending/application/pending_queue_controller.dart';

/// One automatic retry pass when connectivity returns, delayed by an
/// exponential backoff derived from the most-attempted item. Never loops:
/// a failed pass waits for the next reconnect or a manual retry.
class ReconnectRetry extends Notifier<void> {
  static const _log = AppLogger('reconnect');
  Timer? _timer;
  bool _wasOnline = true;

  @override
  void build() {
    final sub = ref
        .watch(connectivityServiceProvider)
        .onlineChanges
        .listen(_onConnectivity);
    // The mock's airplane mode is a second connectivity signal in dev.
    final store = ref.watch(mockStoreProvider);
    void onStore() => _onConnectivity(!store.airplaneMode);
    store.addListener(onStore);
    ref.onDispose(() {
      unawaited(sub.cancel());
      store.removeListener(onStore);
      _timer?.cancel();
    });
  }

  void _onConnectivity(bool online) {
    final regained = online && !_wasOnline;
    _wasOnline = online;
    if (!regained) return;
    unawaited(_scheduleOnePass());
  }

  Future<void> _scheduleOnePass() async {
    final items = await ref.read(pendingQueueRepositoryProvider).all();
    if (items.isEmpty) return;
    final maxAttempts = items.map((w) => w.attempts).reduce(max);
    final delay = backoff(maxAttempts);
    _log.info('online again; retrying ${items.length} in ${delay.inSeconds}s');
    _timer?.cancel();
    _timer = Timer(delay, () {
      unawaited(
        ref
            .read(pendingQueueControllerProvider.notifier)
            .retryAll(includeFailed: false),
      );
    });
  }

  /// 2^attempts seconds, capped at one minute.
  static Duration backoff(int attempts) =>
      Duration(seconds: min(60, 1 << min(attempts, 6)));
}

final reconnectRetryProvider =
    NotifierProvider<ReconnectRetry, void>(ReconnectRetry.new);
