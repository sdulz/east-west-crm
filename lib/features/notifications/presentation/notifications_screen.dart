import 'dart:async';

import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/notifications/application/notification_controllers.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static IconData iconFor(NotificationKind k) => switch (k) {
    NotificationKind.mention => Icons.alternate_email,
    NotificationKind.assignment => Icons.assignment_ind_outlined,
    NotificationKind.invoice => Icons.receipt_long_outlined,
    NotificationKind.reminder => Icons.alarm,
  };

  void _open(BuildContext context, WidgetRef ref, AppNotification n) {
    unawaited(ref.read(notificationActionsProvider.notifier).markRead(n.id));
    final id = n.relatedId;
    if (id == null) return;
    switch (RelatedType.values.asNameMap()[n.relatedType]) {
      case RelatedType.customer:
        unawaited(CustomerDetailRoute(id: id).push<void>(context));
      case RelatedType.opportunity:
        unawaited(OpportunityDetailRoute(id: id).push<void>(context));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = ref.watch(notificationListProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifications),
        actions: [
          TextButton(
            key: const Key('notifications_read_all'),
            onPressed: unread == 0
                ? null
                : () => ref
                      .read(notificationActionsProvider.notifier)
                      .markAllRead(),
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationListProvider.future),
        child: AsyncView<List<AppNotification>>(
          value: items,
          onRetry: () => ref.invalidate(notificationListProvider),
          isEmpty: (v) => v.isEmpty,
          emptyMessage: l.noNotifications,
          data: (list) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final n = list[i];
              return ListTile(
                key: Key('notification_${n.id}'),
                tileColor: n.isUnread
                    ? scheme.primaryContainer.withValues(alpha: 0.35)
                    : null,
                leading: LeadingGlyph(
                  icon: iconFor(n.kind),
                  color: n.isUnread ? scheme.primary : scheme.onSurfaceVariant,
                ),
                title: Text(
                  n.title,
                  style: TextStyle(
                    fontWeight: n.isUnread ? FontWeight.w600 : null,
                  ),
                ),
                subtitle: Text('${n.body}\n${f.dateTime(n.createdAt)}'),
                isThreeLine: true,
                onTap: () => _open(context, ref, n),
              );
            },
          ),
        ),
      ),
    );
  }
}
