import 'package:field_crm/core/logging/app_logger.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/features/opportunities/application/assignment_watcher.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logger redacts emails, phones and secrets', () {
    final out = AppLogger.redact(
      'user sita@fieldcrm.test called +977 9812345678 '
      'token=abc123 password: hunter2',
    );
    expect(out, isNot(contains('sita@')));
    expect(out, isNot(contains('9812345678')));
    expect(out, isNot(contains('abc123')));
    expect(out, isNot(contains('hunter2')));
    expect(out, contains('<email>'));
    expect(out, contains('<phone>'));
  });

  test('uuidV4 is well formed and unique', () {
    final re = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 200; i++) uuidV4()};
    expect(ids.length, 200);
    expect(ids.every(re.hasMatch), isTrue);
  });

  test('assignment watcher flags only opportunities new since baseline', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    Opportunity o(String id) => Opportunity(
      id: id,
      title: id,
      customerId: 'c',
      stageId: 's',
      ownerId: 'me',
      teamId: 't',
      updatedAt: DateTime.utc(2026),
    );
    final w = c.read(assignmentWatcherProvider.notifier)..check([o('a')]);
    expect(c.read(assignmentWatcherProvider), isEmpty);
    w.check([o('a'), o('b')]);
    expect(c.read(assignmentWatcherProvider).map((x) => x.id), ['b']);
    w
      ..dismiss()
      ..check([o('a'), o('b')]);
    expect(c.read(assignmentWatcherProvider), isEmpty);
  });
}
