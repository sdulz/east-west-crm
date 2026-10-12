import 'package:field_crm/app/env.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dev flavor only: airplane mode, forced failures, user switch, reseed.
class DevMenuScreen extends ConsumerWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (!AppEnv.isDev) {
      return Scaffold(body: Center(child: Text(l.permissionDeniedView)));
    }
    final store = ref.watch(mockStoreProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l.devMenu)),
        body: ListView(
          children: [
            SwitchListTile(
              key: const Key('dev_airplane'),
              secondary: const Icon(Icons.airplanemode_active),
              title: Text(l.devAirplane),
              value: store.airplaneMode,
              onChanged: (v) => store.airplaneMode = v,
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l.devFailNext),
              trailing: DropdownButton<String>(
                key: const Key('dev_fail_next'),
                value: switch (store.forceNextFailure) {
                  null => 'none',
                  NetworkFailure() => 'network',
                  TimeoutFailure() => 'timeout',
                  ValidationFailure() => 'validation',
                  PermissionDeniedFailure() => 'permission',
                  ConflictFailure() => 'conflict',
                  UnknownFailure() => 'unknown',
                },
                onChanged: (v) => store.forceNextFailure = switch (v) {
                  'network' => const Failure.network(),
                  'timeout' => const Failure.timeout(),
                  'validation' => const Failure.validation(
                    'Forced validation error (dev)',
                  ),
                  'permission' => const Failure.permissionDenied(),
                  'conflict' => const Failure.conflict(),
                  'unknown' => const Failure.unknown('Forced error (dev)'),
                  _ => null,
                },
                items: [
                  DropdownMenuItem(value: 'none', child: Text(l.devNone)),
                  const DropdownMenuItem(
                    value: 'network',
                    child: Text('network'),
                  ),
                  const DropdownMenuItem(
                    value: 'timeout',
                    child: Text('timeout'),
                  ),
                  const DropdownMenuItem(
                    value: 'validation',
                    child: Text('validation'),
                  ),
                  const DropdownMenuItem(
                    value: 'permission',
                    child: Text('permission'),
                  ),
                  const DropdownMenuItem(
                    value: 'conflict',
                    child: Text('conflict'),
                  ),
                  const DropdownMenuItem(
                    value: 'unknown',
                    child: Text('unknown'),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(title: Text(l.devSwitchUser)),
            for (final u in store.state.users)
              ListTile(
                key: Key('dev_user_${u.id}'),
                leading: const Icon(Icons.person_outline),
                title: Text(u.name),
                subtitle: Text('${u.email} · ${u.role.name}'),
                enabled: u.isActive,
                onTap: () async {
                  final auth = ref.read(authControllerProvider.notifier);
                  await auth.logout();
                  await auth.login(
                    email: u.email,
                    password: store.state.passwords[u.email] ?? '',
                    rememberMe: true,
                  );
                },
              ),
            const Divider(),
            ListTile(
              key: const Key('dev_reset'),
              leading: const Icon(Icons.restart_alt),
              title: Text(l.devResetSeed),
              onTap: () async {
                await store.resetSeed();
                ref.read(refreshTickProvider.notifier).bump();
              },
            ),
          ],
        ),
      ),
    );
  }
}
