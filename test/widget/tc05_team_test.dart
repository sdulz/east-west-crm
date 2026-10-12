import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('TC-05 team view hidden for salesperson', (tester) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));
    await tester.tap(find.text('Profile'));
    await pumpUntilFound(tester, find.byKey(const Key('profile_logout')));
    expect(find.byKey(const Key('profile_team')), findsNothing);
    await finish(tester);
  });

  testWidgets('TC-05 team view correct for supervisor', (tester) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester, email: 'maya@fieldcrm.test');
    await pumpUntilFound(tester, find.byType(HomeScreen));
    await tester.tap(find.text('Profile'));
    await pumpUntilFound(tester, find.byKey(const Key('profile_team')));
    await tester.tap(find.byKey(const Key('profile_team')));
    await pumpUntilFound(tester, find.byKey(const Key('team_member_u-sita')));
    expect(find.byKey(const Key('team_member_u-ram')), findsOneWidget);
    final closed = h.store.state.stages
        .where((s) => s.isWon || s.isFolded)
        .map((s) => s.id)
        .toSet();
    final open = h.store.state.opportunities
        .where((o) => o.ownerId == 'u-sita' && !closed.contains(o.stageId))
        .length;
    expect(find.textContaining('$open open'), findsWidgets);
    await finish(tester);
  });
}
