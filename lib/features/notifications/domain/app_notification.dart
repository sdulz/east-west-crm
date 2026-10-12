import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

enum NotificationKind { mention, assignment, invoice, reminder }

/// In-app notification addressed to one user.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    required NotificationKind kind,
    required String title,
    required String body,
    required DateTime createdAt,
    String? relatedType,
    String? relatedId,
    DateTime? readAt,
  }) = _AppNotification;
  const AppNotification._();

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  bool get isUnread => readAt == null;
}
