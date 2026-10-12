import 'package:field_crm/app/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

/// E2E on a real device/emulator (dev flavor, mock backend):
///   patrol test --target integration_test/app_test.dart \
///     --dart-define-from-file=env/dev.json
void main() {
  patrolTest('TC-02 end-to-end: login → search → log → follow-up → dashboard', (
    $,
  ) async {
    await bootstrap();
    await $(#login_email).waitUntilVisible();
    await $(#login_email).enterText('sita@fieldcrm.test');
    await $(#login_password).enterText('password');
    await $(#login_submit).tap();
    await $(#quick_add_fab).waitUntilVisible();

    await $(Icons.search).tap();
    await $(#search_field).enterText('Himalayan');
    await $('Himalayan Traders').waitUntilVisible();
    await $('Himalayan Traders').tap();

    await $(FloatingActionButton).tap();
    await $(#quick_interaction).tap();
    await $(#activity_summary).enterText('E2E call');
    await $(#activity_outcome).enterText('OK');
    await $(#activity_save).tap();
    await $('Saved').waitUntilVisible();

    await $(FloatingActionButton).tap();
    await $(#quick_followup).tap();
    await $(#activity_summary).enterText('E2E follow-up');
    await $(#due_picker).tap();
    await $('OK').tap();
    await $('OK').tap();
    await $(#activity_save).tap();
    await $('Saved').waitUntilVisible();

    await $.platformAutomator.android.pressBack();
    await $.platformAutomator.android.pressBack();
    await $('Today').waitUntilVisible();
  });
}
