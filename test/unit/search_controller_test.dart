import 'package:field_crm/features/search/application/search_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  test('FR-MOB-003 debounces 300 ms and drops stale results', () async {
    final h = await TestHarness.create();
    addTearDown(h.dispose);
    h.store.setCurrentUser('u-sita');
    final sub = h.container.listen(searchControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final ctrl = h.container.read(searchControllerProvider.notifier)
      ..setQuery('him')
      ..setQuery('himal');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(
      h.container.read(searchControllerProvider),
      isA<AsyncLoading<Object?>>(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final r = h.container.read(searchControllerProvider).value!;
    expect(r.customers.map((c) => c.name), contains('Himalayan Traders'));
    ctrl.setQuery('');
    expect(h.container.read(searchControllerProvider).value!.isEmpty, isTrue);
  });
}
