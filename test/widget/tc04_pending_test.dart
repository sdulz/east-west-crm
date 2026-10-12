import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('TC-04 network failure → Pending badge → retry → success', (
    tester,
  ) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));

    await tester.tap(find.text('Clients'));
    await pumpUntilFound(tester, find.byKey(const Key('customer_add')));
    await tester.tap(find.byKey(const Key('customer_add')));
    await pumpUntilFound(tester, find.byKey(const Key('customer_name')));
    await tester.enterText(
      find.byKey(const Key('customer_name')),
      'Offline Co',
    );
    // "Fail next call" is consumed by whichever mock call comes next.
    h.store.forceNextFailure = const Failure.network();
    await tester.tap(find.byKey(const Key('customer_save')));
    await pumpUntilFound(
      tester,
      find.text('No connection. Saved to pending queue.'),
    );
    expect(find.text('Saved'), findsNothing);
    // Not merged into confirmed data.
    expect(h.store.state.customers.any((c) => c.name == 'Offline Co'), isFalse);

    final queue = await h.container.read(pendingQueueRepositoryProvider).all();
    expect(queue.single.operation, WriteOperation.customerCreate);
    expect(queue.single.status, PendingStatus.pending);

    // Pending centre shows it; retry succeeds now that the mock is healthy.
    await tester.tap(find.text('Profile'));
    await pumpUntilFound(tester, find.byKey(const Key('profile_pending')));
    await tester.tap(find.byKey(const Key('profile_pending')));
    await pumpUntilFound(tester, find.text('New customer'));
    expect(find.text('Pending', findRichText: true), findsWidgets);
    await tester.tap(find.byKey(Key('retry_${queue.single.id}')));
    await pumpUntilFound(
      tester,
      find.text('Nothing pending. All changes are confirmed.'),
    );
    expect(h.store.state.customers.any((c) => c.name == 'Offline Co'), isTrue);
    expect(
      await h.container.read(pendingQueueRepositoryProvider).all(),
      isEmpty,
    );
    await finish(tester);
  });

  testWidgets('TC-04 validation failure is shown verbatim and NOT queued', (
    tester,
  ) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));
    await tester.tap(find.text('Clients'));
    await pumpUntilFound(tester, find.byKey(const Key('customer_add')));
    await tester.tap(find.byKey(const Key('customer_add')));
    await pumpUntilFound(tester, find.byKey(const Key('customer_name')));
    await tester.enterText(
      find.byKey(const Key('customer_name')),
      'Bad Phone Co',
    );
    // Passes the (looser) inline check, fails the server-style check.
    await tester.enterText(
      find.byKey(const Key('customer_phone')),
      '12345678901234567890123',
    );
    await tester.tap(find.byKey(const Key('customer_save')));
    await pumpUntilFound(tester, find.textContaining('Phone must be digits'));
    expect(
      await h.container.read(pendingQueueRepositoryProvider).all(),
      isEmpty,
    );
    expect(
      h.store.state.customers.any((c) => c.name == 'Bad Phone Co'),
      isFalse,
    );
    await finish(tester);
  });

  testWidgets(
    'TC-04 discard asks for confirmation; retry-all and failed state',
    (tester) async {
      final h = await TestHarness.create();
      addTearDown(h.dispose);
      await pumpApp(tester, h);
      await login(tester);
      await pumpUntilFound(tester, find.byType(HomeScreen));
      h.store.airplaneMode = true;
      await tester.tap(find.text('Clients'));
      await pumpUntilFound(tester, find.byKey(const Key('customer_add')));
      await tester.tap(find.byKey(const Key('customer_add')));
      await pumpUntilFound(tester, find.byKey(const Key('customer_name')));
      await tester.enterText(
        find.byKey(const Key('customer_name')),
        'Queued Co',
      );
      await tester.tap(find.byKey(const Key('customer_save')));
      await pumpUntilFound(
        tester,
        find.text('No connection. Saved to pending queue.'),
      );
      await tester.tap(find.text('Profile'));
      await pumpUntilFound(tester, find.byKey(const Key('profile_pending')));
      await tester.tap(find.byKey(const Key('profile_pending')));
      await pumpUntilFound(tester, find.byKey(const Key('retry_all')));
      // Still offline: one pass, item stays pending with attempts = 1.
      await tester.tap(find.byKey(const Key('retry_all')));
      await pumpUntilFound(tester, find.textContaining('1 attempt'));
      final id = (await h.container.read(pendingQueueRepositoryProvider).all())
          .single
          .id;
      await tester.tap(find.byKey(Key('discard_$id')));
      await pumpUntilFound(tester, find.byKey(const Key('discard_confirm')));
      await tester.tap(find.byKey(const Key('discard_confirm')));
      await pumpUntilFound(
        tester,
        find.text('Nothing pending. All changes are confirmed.'),
      );
      await finish(tester);
    },
  );
}
