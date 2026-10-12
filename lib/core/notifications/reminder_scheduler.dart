import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// A scheduled local notification. [title]/[body] must never contain customer
/// names, phone numbers or amounts (FR-MOB-012); callers pass neutral text.
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.payload,
  });
  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String? payload;
}

abstract interface class ReminderScheduler {
  Future<void> initialize();
  Future<void> schedule(ScheduledReminder reminder);
  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<List<int>> pendingIds();
}

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'follow_ups';

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> schedule(ScheduledReminder r) async {
    final when = tz.TZDateTime.from(r.at, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: r.id,
      title: r.title,
      body: r.body,
      scheduledDate: when,
      payload: r.payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Follow-up reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<int>> pendingIds() async =>
      (await _plugin.pendingNotificationRequests()).map((r) => r.id).toList();
}

/// Records calls instead of touching the OS. Used by tests and the dev flavor
/// on platforms without notification support.
class FakeReminderScheduler implements ReminderScheduler {
  final Map<int, ScheduledReminder> scheduled = {};
  final List<int> cancelled = [];

  @override
  Future<void> initialize() async {}
  @override
  Future<void> schedule(ScheduledReminder r) async => scheduled[r.id] = r;
  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelled.addAll(scheduled.keys);
    scheduled.clear();
  }

  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();
}
