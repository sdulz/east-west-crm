import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/notifications/domain/app_notification.dart';

abstract interface class NotificationRepository {
  /// Newest first, for the current user.
  Future<Result<List<AppNotification>, Failure>> list();
  Future<Result<void, Failure>> markRead(String id);
  Future<Result<void, Failure>> markAllRead();
}
