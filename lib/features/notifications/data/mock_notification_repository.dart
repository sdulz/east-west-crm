import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';
import 'package:field_crm/features/notifications/domain/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this.store);
  final MockStore store;

  List<AppNotification> get _all => store.state.notifications;

  @override
  Future<Result<List<AppNotification>, Failure>> list() => store.call(() {
    final me = store.currentUser;
    return _all.where((n) => n.userId == me.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<Result<void, Failure>> markRead(String id) => store.call(() {
    final me = store.currentUser;
    final i = _all.indexWhere((n) => n.id == id && n.userId == me.id);
    if (i >= 0 && _all[i].readAt == null) {
      _all[i] = _all[i].copyWith(readAt: store.clock.now());
    }
  }, write: true);

  @override
  Future<Result<void, Failure>> markAllRead() => store.call(() {
    final me = store.currentUser;
    final now = store.clock.now();
    for (var i = 0; i < _all.length; i++) {
      if (_all[i].userId == me.id && _all[i].readAt == null) {
        _all[i] = _all[i].copyWith(readAt: now);
      }
    }
  }, write: true);
}
