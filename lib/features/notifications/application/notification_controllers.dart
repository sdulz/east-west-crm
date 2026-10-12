import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_controllers.g.dart';

@Riverpod(keepAlive: true)
Future<List<AppNotification>> notificationList(Ref ref) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(notificationRepositoryProvider).list().orThrow;
}

@riverpod
int unreadNotificationCount(Ref ref) =>
    ref
        .watch(notificationListProvider)
        .value
        ?.where((n) => n.isUnread)
        .length ??
    0;

@Riverpod(keepAlive: true)
class NotificationActions extends _$NotificationActions {
  @override
  void build() {}

  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markRead(id);
    ref.read(refreshTickProvider.notifier).bump();
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.read(refreshTickProvider.notifier).bump();
  }
}
