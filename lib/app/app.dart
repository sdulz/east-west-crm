import 'dart:async';

import 'package:field_crm/app/env.dart';
import 'package:field_crm/app/router.dart';
import 'package:field_crm/app/theme.dart';
import 'package:field_crm/core/l10n/generated/app_localizations.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/pending/application/reconnect_retry.dart';
import 'package:field_crm/features/profile/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class FieldCrmApp extends ConsumerWidget {
  const FieldCrmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings =
        ref.watch(settingsControllerProvider).value ?? const AppSettings();
    ref.watch(reconnectRetryProvider); // keep the reconnect watcher alive
    Intl.defaultLocale = settings.locale?.languageCode;
    return MaterialApp.router(
      title: AppEnv.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => InactivityGuard(
        child: PrivacyScreen(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// Locks the session after [AppEnv.inactivityTimeoutMinutes] without input.
class InactivityGuard extends ConsumerStatefulWidget {
  const InactivityGuard({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends ConsumerState<InactivityGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    if (AppEnv.inactivityTimeoutMinutes <= 0) return;
    _timer = Timer(
      const Duration(minutes: AppEnv.inactivityTimeoutMinutes),
      () {
        if (ref.read(currentUserProvider) != null) {
          ref.read(appLockProvider.notifier).lock();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _reset(),
    child: widget.child,
  );
}

/// Covers the UI while the app is inactive so the app-switcher snapshot does
/// not show customer data. Configurable via PRIVACY_SCREEN.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({required this.child, super.key});
  final Widget child;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final AppLifecycleListener _listener;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: () => _set(true),
      onHide: () => _set(true),
      onResume: () => _set(false),
    );
  }

  void _set(bool hidden) {
    if (AppEnv.privacyScreen && mounted) setState(() => _hidden = hidden);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_hidden)
        Positioned.fill(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: const Center(
              child: Icon(Icons.handshake_outlined, size: 64),
            ),
          ),
        ),
    ],
  );
}
