import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';

final notificationListProvider =
    FutureProvider<List<AppNotification>>((ref) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref.watch(notificationRepositoryProvider).list().orThrow;
});

final unreadNotificationCountProvider = Provider<int>((ref) =>
    ref
        .watch(notificationListProvider)
        .value
        ?.where((n) => n.isUnread)
        .length ??
    0);

class NotificationActions extends Notifier<void> {
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

final notificationActionsProvider =
    NotifierProvider<NotificationActions, void>(NotificationActions.new);
