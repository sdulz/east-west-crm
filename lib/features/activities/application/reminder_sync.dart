import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/notifications/reminder_scheduler.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';

class ReminderSync extends Notifier<void> {
  @override
  void build() {}
  static const window = Duration(days: 7);

  static int notificationId(String activityId) =>
      activityId.hashCode & 0x7fffffff;

  Future<void> sync(
    List<Activity> followUps, {
    required String title,
    required String Function(String time) body,
  }) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    final me = ref.read(currentUserProvider);
    final now = ref.read(clockProvider).now();
    final tzName = me?.timezone ?? 'UTC';
    await scheduler.cancelAll();
    for (final a in followUps) {
      final due = a.dueAt;
      if (a.state == ActivityState.done || due == null) continue;
      if (!due.isAfter(now) || due.isAfter(now.add(window))) continue;
      final local = inZone(due, tzName);
      await scheduler.schedule(
        ScheduledReminder(
          id: notificationId(a.id),
          at: due,
          title: title,
          body: body(DateFormat.jm().format(local)),
          payload: a.id,
        ),
      );
    }
  }

  Future<void> cancelFor(String activityId) =>
      ref.read(reminderSchedulerProvider).cancel(notificationId(activityId));
}

final reminderSyncProvider =
    NotifierProvider<ReminderSync, void>(ReminderSync.new);
