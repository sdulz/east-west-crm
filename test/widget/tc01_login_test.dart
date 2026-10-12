import 'package:field_crm/app/providers.dart';
import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:field_crm/features/opportunities/presentation/opportunity_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('TC-01 invalid and inactive users are rejected clearly', (
    tester,
  ) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester, password: 'wrong');
    await pumpUntilFound(tester, find.byKey(const Key('login_error')));
    expect(find.text('Email or password is incorrect.'), findsOneWidget);

    await login(tester, email: 'hari@fieldcrm.test');
    await pumpUntilFound(
      tester,
      find.text('This account is inactive. Contact your supervisor.'),
    );
    await finish(tester);
  });

  testWidgets('TC-01 salesperson sees only own records', (tester) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));
    await tester.tap(find.text('CRM'));
    await pumpUntilFound(tester, find.byKey(const Key('open_list')));
    await tester.tap(find.byKey(const Key('open_list')));
    await pumpUntilFound(tester, find.byType(OpportunityRow));
    final mine = h.store.state.opportunities.where(
      (o) => o.ownerId == 'u-sita',
    );
    final theirs = h.store.state.opportunities.where(
      (o) => o.ownerId == 'u-ram',
    );
    final rows = tester
        .widgetList<OpportunityRow>(find.byType(OpportunityRow))
        .map((r) => r.o.ownerId)
        .toSet();
    expect(rows, {'u-sita'});
    expect(mine, isNotEmpty);
    expect(theirs, isNotEmpty);
    // Remember-me stored the token in secure storage only.
    expect(h.secure.values['session_token'], isNotNull);
    await finish(tester);
  });

  testWidgets('TC-01 supervisor sees the team', (tester) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester, email: 'maya@fieldcrm.test');
    await pumpUntilFound(tester, find.byType(HomeScreen));
    await tester.tap(find.text('CRM'));
    await pumpUntilFound(tester, find.byKey(const Key('open_list')));
    await tester.tap(find.byKey(const Key('open_list')));
    await pumpUntilFound(tester, find.byType(OpportunityRow));
    final owners = tester
        .widgetList<OpportunityRow>(find.byType(OpportunityRow))
        .map((r) => r.o.ownerId)
        .toSet();
    expect(owners, {'u-sita', 'u-ram'});
    await finish(tester);
  });

  testWidgets('TC-01 logout warns about pending items and wipes the queue', (
    tester,
  ) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));
    // Queue one write directly.
    final c = h.store.state.customers.first;
    h.store.airplaneMode = true;
    await tester.tap(find.text('Clients'));
    await pumpUntilFound(tester, find.byKey(const Key('customer_add')));
    await tester.tap(find.byKey(const Key('customer_add')));
    await pumpUntilFound(tester, find.byKey(const Key('customer_name')));
    await tester.enterText(find.byKey(const Key('customer_name')), 'Queued Co');
    await tester.tap(find.byKey(const Key('customer_save')));
    await pumpUntilFound(
      tester,
      find.text('No connection. Saved to pending queue.'),
    );
    expect(c, isNotNull);
    await tester.tap(find.text('Profile'));
    await pumpUntilFound(tester, find.byKey(const Key('profile_logout')));
    await tester.ensureVisible(find.byKey(const Key('profile_logout')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_logout')));
    await pumpUntilFound(
      tester,
      find.text('1 pending change will be discarded.'),
    );
    await tester.tap(find.text('Log out anyway'));
    await pumpUntilFound(tester, find.byKey(const Key('login_email')));
    expect(
      await h.container.read(pendingQueueRepositoryProvider).all(),
      isEmpty,
    );
    expect(h.secure.values['session_token'], isNull);
    await finish(tester);
  });
}
