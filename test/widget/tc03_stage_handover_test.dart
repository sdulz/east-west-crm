import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:field_crm/features/opportunities/presentation/opportunity_detail_screen.dart';
import 'package:field_crm/features/opportunities/presentation/opportunity_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('TC-03 allowed and rejected stage transitions', (tester) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));
    final o = h.store.state.opportunities.firstWhere(
      (o) => o.ownerId == 'u-sita' && o.stageId == 's-new',
    );
    await tester.tap(find.text('CRM'));
    await pumpUntilFound(tester, find.byType(OpportunityRow));
    await tester.scrollUntilVisible(
      find.byKey(Key('opportunity_${o.id}')),
      200,
    );
    await tester.tap(find.byKey(Key('opportunity_${o.id}')));
    await pumpUntilFound(tester, find.byType(OpportunityDetailScreen));
    await pumpUntilFound(tester, find.byKey(const Key('stage_picker')));
    await tester.tap(find.byKey(const Key('stage_picker')));
    await pumpUntilFound(tester, find.byKey(const Key('stage_option_s-won')));
    // Disallowed transition is disabled in the picker.
    final won = tester.widget<PopupMenuItem<Object?>>(
      find.byKey(const Key('stage_option_s-won')),
    );
    expect(won.enabled, isFalse);
    await tester.tap(find.byKey(const Key('stage_option_s-qualified')));
    await pumpUntilFound(tester, find.text('Moved to Qualified'));
    expect(
      h.store.state.opportunities.firstWhere((x) => x.id == o.id).stageId,
      's-qualified',
    );

    // Server-side rejection (e.g. stale client) reverts with the reason.
    h.store.forceNextFailure = null;
    h.store.replaceStateStage(o.id, 's-new');
    await tester.tap(find.byKey(const Key('stage_picker')));
    await pumpUntilFound(
      tester,
      find.byKey(const Key('stage_option_s-proposal')),
    );
    await tester.tap(find.byKey(const Key('stage_option_s-proposal')));
    await pumpUntilFound(tester, find.textContaining('not allowed'));
    await finish(tester);
    await h.dispose();
  });

  testWidgets('TC-03 handover shows the owner confirmed by the repository', (
    tester,
  ) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);
    await login(tester, email: 'maya@fieldcrm.test');
    await pumpUntilFound(tester, find.byType(HomeScreen));
    final o = h.store.state.opportunities.firstWhere(
      (o) => o.ownerId == 'u-sita',
    );
    await tester.tap(find.text('CRM'));
    await pumpUntilFound(tester, find.byType(OpportunityRow));
    await tester.scrollUntilVisible(
      find.byKey(Key('opportunity_${o.id}')),
      200,
    );
    await tester.tap(find.byKey(Key('opportunity_${o.id}')));
    await pumpUntilFound(tester, find.byKey(const Key('handover_button')));
    await tester.tap(find.byKey(const Key('handover_button')));
    await pumpUntilFound(tester, find.byKey(const Key('handover_user_u-ram')));
    await tester.tap(find.byKey(const Key('handover_user_u-ram')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('handover_confirm')));
    await pumpUntilFound(tester, find.text('Owner is now Ram Thapa'));
    await pumpUntilFound(
      tester,
      find.descendant(
        of: find.byKey(const Key('owner_field')),
        matching: find.text('Ram Thapa'),
      ),
    );
    expect(
      h.store.state.opportunities.firstWhere((x) => x.id == o.id).ownerId,
      'u-ram',
    );
    await finish(tester);
    await h.dispose();
  });

  testWidgets('salesperson cannot see the handover button', (tester) async {
    final h = await TestHarness.create();
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));
    final o = h.store.state.opportunities.firstWhere(
      (o) => o.ownerId == 'u-sita',
    );
    await tester.tap(find.text('CRM'));
    await pumpUntilFound(tester, find.byType(OpportunityRow));
    await tester.scrollUntilVisible(
      find.byKey(Key('opportunity_${o.id}')),
      200,
    );
    await tester.tap(find.byKey(Key('opportunity_${o.id}')));
    await pumpUntilFound(tester, find.byKey(const Key('owner_field')));
    expect(find.byKey(const Key('handover_button')), findsNothing);
    await finish(tester);
    await h.dispose();
  });
}
