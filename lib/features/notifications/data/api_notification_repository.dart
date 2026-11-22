import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';
import 'package:field_crm/features/notifications/domain/notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this.client);

  final CrmApiClient client;

  @override
  Future<Result<List<AppNotification>, Failure>> list() async {
    final res = await client.get<List<AppNotification>>(
      ApiConstant.notificationsUrl,
      params: const {'page': 1, 'limit': 100},
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              _parseNotification(Map<String, dynamic>.from(item)),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
    );
    // Gracefully return an empty list if the backend Odoo module has not been
    // upgraded in PostgreSQL yet (`relation "mobile_notification" does not exist`).
    if (res case Err(error: ValidationFailure(:final message))
        when message.contains('mobile_notification')) {
      return const Ok(<AppNotification>[]);
    }
    return res;
  }

  @override
  Future<Result<void, Failure>> markRead(String id) {
    return client.post<void>(
      ApiConstant.notificationReadUrl(id),
      parse: (_) {},
    );
  }

  @override
  Future<Result<void, Failure>> markAllRead() {
    return client.post<void>(
      ApiConstant.notificationsReadAllUrl,
      parse: (_) {},
    );
  }

  AppNotification _parseNotification(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final userId = json['user_id']?.toString() ?? client.currentUser?.id ?? '1';
    final kindStr = (json['kind'] ?? 'reminder').toString().toLowerCase();
    final kind = switch (kindStr) {
      'mention' => NotificationKind.mention,
      'assignment' => NotificationKind.assignment,
      'invoice' => NotificationKind.invoice,
      _ => NotificationKind.reminder,
    };
    final title = (json['title'] ?? '').toString();
    final body = (json['body'] ?? '').toString();
    final relatedType = json['related_type']?.toString();
    final relatedId = json['related_id']?.toString();

    final createdAt =
        CrmApiClient.parseUtcDate(json['created_at']?.toString()) ??
        DateTime.now().toUtc();
    final readAt = CrmApiClient.parseUtcDate(json['read_at']?.toString());

    return AppNotification(
      id: id,
      userId: userId,
      kind: kind,
      title: title,
      body: body,
      relatedType: relatedType,
      relatedId: relatedId,
      createdAt: createdAt,
      readAt: readAt,
    );
  }
}
