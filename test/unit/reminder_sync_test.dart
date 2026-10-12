import 'package:field_crm/features/activities/application/reminder_sync.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late TestHarness h;
  final now = DateTime.utc(2026, 10, 12, 9);

  setUp(() async {
    h = await TestHarness.create(now: now);
    await h.container
        .read(authControllerProvider.notifier)
        .login(
          email: 'sita@fieldcrm.test',
          password: 'password',
          rememberMe: false,
        );
  });
  tearDown(() => h.dispose());

  Activity todo(String id, DateTime due) => Activity(
    id: id,
    type: ActivityType.todo,
    relatedType: RelatedType.customer,
    relatedId: 'c-001',
    summary: 'Call Himalayan Traders about Rs 250000 on +977 9800000000',
    ownerId: 'u-sita',
    dueAt: due,
    updatedAt: now,
  );

  test(
    'TC-06 schedules only the next 7 days, neutral text, cancels on complete',
    () async {
      final sync = h.container.read(reminderSyncProvider.notifier);
      await sync.sync(
        [
          todo('past', now.subtract(const Duration(hours: 1))),
          todo('soon', now.add(const Duration(hours: 5))),
          todo('far', now.add(const Duration(days: 8))),
          todo(
            'done',
            now.add(const Duration(hours: 2)),
          ).copyWith(state: ActivityState.done),
        ],
        title: 'Follow-up reminder',
        body: (t) => 'You have a follow-up due at $t.',
      );
      final ids = h.reminders.scheduled.keys.toList();
      expect(ids, [ReminderSync.notificationId('soon')]);
      final r = h.reminders.scheduled.values.single;
      // 14:00 UTC == 19:45 in Asia/Kathmandu (the user's timezone).
      // intl inserts U+202F before the meridiem.
      expect(
        r.body.replaceAll('\u202f', ' '),
        'You have a follow-up due at 7:45 PM.',
      );
      expect(r.title, 'Follow-up reminder');
      for (final s in [r.title, r.body, r.payload ?? '']) {
        expect(s, isNot(contains('Himalayan')));
        expect(s, isNot(contains('250000')));
        expect(s, isNot(contains('+977')));
      }
      expect(r.payload, 'soon');

      await sync.cancelFor('soon');
      expect(h.reminders.scheduled, isEmpty);
      expect(
        h.reminders.cancelled,
        contains(ReminderSync.notificationId('soon')),
      );
    },
  );

  test('every sync replaces the previous schedule', () async {
    final sync = h.container.read(reminderSyncProvider.notifier);
    await sync.sync(
      [todo('a', now.add(const Duration(hours: 1)))],
      title: 't',
      body: (t) => t,
    );
    await sync.sync(
      [todo('b', now.add(const Duration(hours: 2)))],
      title: 't',
      body: (t) => t,
    );
    expect(h.reminders.scheduled.keys, [ReminderSync.notificationId('b')]);
  });
}
