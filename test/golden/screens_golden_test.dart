// ignore_for_file: discarded_futures -- goldenTest returns a Future by design
import 'package:alchemist/alchemist.dart';
import 'package:field_crm/app/theme.dart';
import 'package:field_crm/core/l10n/generated/app_localizations.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/auth/presentation/login_screen.dart';
import 'package:field_crm/features/dashboard/presentation/home_screen.dart';
import 'package:field_crm/features/pending/presentation/pending_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_app.dart';

/// Key screens in light + dark and at 200% text scale (a11y requirement).
void main() {
  Widget wrap(
    TestHarness h,
    Widget screen, {
    required Brightness brightness,
    double textScale = 1,
  }) => UncontrolledProviderScope(
    container: h.container,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp.router(
        theme: brightness == Brightness.light
            ? AppTheme.light()
            : AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => screen)],
        ),
      ),
    ),
  );

  Future<TestHarness> loggedIn() async {
    final h = await TestHarness.create(now: DateTime.utc(2026, 10, 12, 9));
    await h.container
        .read(authControllerProvider.notifier)
        .login(
          email: 'sita@fieldcrm.test',
          password: 'password',
          rememberMe: false,
        );
    return h;
  }

  for (final brightness in Brightness.values) {
    final mode = brightness.name;
    goldenTest(
      'login $mode',
      fileName: 'login_$mode',
      pumpBeforeTest: (t) => t.pump(const Duration(seconds: 1)),
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(
          width: 400,
          height: 700,
        ),
        children: [
          GoldenTestScenario(
            name: 'default',
            child: FutureBuilder(
              future: TestHarness.create(),
              builder: (_, s) => s.hasData
                  ? wrap(s.data!, const LoginScreen(), brightness: brightness)
                  : const SizedBox(),
            ),
          ),
          GoldenTestScenario(
            name: 'text 200%',
            child: FutureBuilder(
              future: TestHarness.create(),
              builder: (_, s) => s.hasData
                  ? wrap(
                      s.data!,
                      const LoginScreen(),
                      brightness: brightness,
                      textScale: 2,
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'home $mode',
      fileName: 'home_$mode',
      pumpBeforeTest: (t) => t.pump(const Duration(seconds: 2)),
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(
          width: 400,
          height: 760,
        ),
        children: [
          GoldenTestScenario(
            name: 'default',
            child: FutureBuilder(
              future: loggedIn(),
              builder: (_, s) => s.hasData
                  ? wrap(s.data!, const HomeScreen(), brightness: brightness)
                  : const SizedBox(),
            ),
          ),
          GoldenTestScenario(
            name: 'text 200%',
            child: FutureBuilder(
              future: loggedIn(),
              builder: (_, s) => s.hasData
                  ? wrap(
                      s.data!,
                      const HomeScreen(),
                      brightness: brightness,
                      textScale: 2,
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'pending centre $mode',
      fileName: 'pending_$mode',
      pumpBeforeTest: (t) => t.pump(const Duration(seconds: 1)),
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(
          width: 400,
          height: 500,
        ),
        children: [
          GoldenTestScenario(
            name: 'empty',
            child: FutureBuilder(
              future: loggedIn(),
              builder: (_, s) => s.hasData
                  ? wrap(
                      s.data!,
                      const PendingCenterScreen(),
                      brightness: brightness,
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}
