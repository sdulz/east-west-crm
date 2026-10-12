import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('boots to login, logs in, shows home', (tester) async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    await pumpApp(tester, h);
    await login(tester);
    await pumpUntilFound(tester, find.byType(HomeScreen));
    expect(find.byKey(const Key('quick_add_fab')), findsOneWidget);
    await finish(tester);
  });
}
