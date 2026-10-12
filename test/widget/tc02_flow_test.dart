import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/customers/presentation/customer_detail_screen.dart';
import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'TC-02 search customer → log interaction → schedule follow-up → dashboard',
    (tester) async {
      final now = DateTime.now().toUtc();
      final h = await TestHarness.create(now: now);
      await pumpApp(tester, h);
      await login(tester);
      await pumpUntilFound(tester, find.byType(HomeScreen));

      // Search (300 ms debounce).
      await tester.tap(find.byIcon(Icons.search).first);
      await pumpUntilFound(tester, find.byKey(const Key('search_field')));
      await tester.enterText(
        find.byKey(const Key('search_field')),
        'Himalayan',
      );
      await pumpUntilFound(tester, find.text('Himalayan Traders'));
      await tester.tap(find.text('Himalayan Traders'));
      await pumpUntilFound(tester, find.byType(CustomerDetailScreen));

      // Quick Add from the record is pre-filled → Log interaction.
      await tester.tap(find.byTooltip('Quick add'));
      await pumpUntilFound(tester, find.byKey(const Key('quick_interaction')));
      await tester.tap(find.byKey(const Key('quick_interaction')));
      await pumpUntilFound(tester, find.byKey(const Key('activity_summary')));
      await tester.enterText(
        find.byKey(const Key('activity_summary')),
        'Intro call',
      );
      await tester.enterText(
        find.byKey(const Key('activity_outcome')),
        'Interested',
      );
      await tester.tap(find.byKey(const Key('activity_save')));
      await pumpUntilFound(tester, find.text('Saved'));
      await pumpUntilFound(tester, find.byType(CustomerDetailScreen));
      final logged = h.store.state.activities.where(
        (a) => a.summary == 'Intro call',
      );
      expect(logged.single.state, ActivityState.done);
      expect(logged.single.relatedId, 'c-001');

      // Schedule a follow-up for later today.
      await tester.tap(find.byTooltip('Quick add'));
      await pumpUntilFound(tester, find.byKey(const Key('quick_followup')));
      await tester.tap(find.byKey(const Key('quick_followup')));
      await pumpUntilFound(tester, find.byKey(const Key('activity_summary')));
      await tester.enterText(
        find.byKey(const Key('activity_summary')),
        'Send quote',
      );
      await tester.tap(find.byKey(const Key('due_picker')));
      await pumpUntilFound(tester, find.text('OK'));
      await tester.tap(find.text('OK')); // date
      await pumpUntilFound(tester, find.text('OK'));
      await tester.tap(find.text('OK')); // time
      await tester.pump();
      await tester.tap(find.byKey(const Key('activity_save')));
      await pumpUntilFound(tester, find.text('Saved'));
      final fu = h.store.state.activities.firstWhere(
        (a) => a.summary == 'Send quote',
      );
      expect(fu.type, ActivityType.todo);
      expect(fu.dueAt, isNotNull);

      // Appears on the dashboard (Today or Overdue depending on wall clock).
      await tester.tap(find.byTooltip('Back'));
      await tester.tap(find.byTooltip('Back'));
      await pumpUntilFound(tester, find.byType(HomeScreen));
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pump();
      final dueBefore = fu.dueAt!.isBefore(now);
      await tester.tap(find.text(dueBefore ? 'Overdue' : 'Today').first);
      await pumpUntilFound(tester, find.text('Send quote'));
      // Reminder scheduled only when still in the future.
      if (!dueBefore) {
        expect(
          h.reminders.scheduled.values.map((r) => r.payload),
          contains(fu.id),
        );
        expect(
          h.reminders.scheduled.values.every(
            (r) => !r.body.contains('Himalayan'),
          ),
          isTrue,
        );
      }
      await finish(tester);
      await h.dispose();
    },
  );
}
