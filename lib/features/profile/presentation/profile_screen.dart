import 'dart:async';
import 'dart:io';

import 'package:field_crm/app/env.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/l10n/generated/app_localizations.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/pending/application/pending_queue_controller.dart';
import 'package:field_crm/features/profile/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

String _roleLabel(AppLocalizations l, UserRole role) =>
    role == UserRole.supervisor ? l.roleSupervisor : l.roleSalesperson;

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometric = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final r = await Future.wait([
      ref.read(authControllerProvider.notifier).isBiometricEnabled(),
      ref.read(biometricAuthProvider).isAvailable(),
    ]);
    if (mounted) {
      setState(() {
        _biometric = r[0];
        _biometricAvailable = r[1];
      });
    }
  }

  Future<void> _logout() async {
    final l = context.l10n;
    final pending = ref.read(pendingCountProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logout),
        content: Text(
          pending > 0 ? l.logoutPendingWarning(pending) : l.logoutConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('logout_confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(pending > 0 ? l.logoutConfirm : l.logout),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    final perms = ref.watch(permissionsProvider);
    final settings =
        ref.watch(settingsControllerProvider).value ?? const AppSettings();
    final pending = ref.watch(pendingCountProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (user != null)
            Panel(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (user.avatarPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.file(
                        File(user.avatarPath!),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    LeadingGlyph(text: user.name[0], size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_roleLabel(l, user.role)} · ${user.timezone}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('profile_edit'),
                    tooltip: l.editProfile,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        const ProfileEditRoute().push<void>(context),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                ListTile(
                  key: const Key('profile_change_password'),
                  leading: const Icon(Icons.password_outlined),
                  title: Text(l.changePassword),
                  onTap: () => const ChangePasswordRoute().push<void>(context),
                ),
                ListTile(
                  key: const Key('profile_invoices'),
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(l.pendingInvoices),
                  onTap: () => const PendingInvoicesRoute().push<void>(context),
                ),
                ListTile(
                  key: const Key('profile_pending'),
                  leading: const Icon(Icons.sync_problem),
                  title: Text(l.pendingCenter),
                  trailing: pending > 0 ? Badge.count(count: pending) : null,
                  onTap: () => const PendingRoute().push<void>(context),
                ),
                if (perms.canViewTeam)
                  ListTile(
                    key: const Key('profile_team'),
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(l.team),
                    onTap: () => const TeamRoute().push<void>(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: Text(l.themeMode),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      onChanged: (m) => m == null
                          ? null
                          : ref
                                .read(settingsControllerProvider.notifier)
                                .setThemeMode(m),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(l.themeSystem),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(l.themeLight),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(l.themeDark),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.language),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.locale?.languageCode ?? '',
                      onChanged: (v) => ref
                          .read(settingsControllerProvider.notifier)
                          .setLocale(v == null || v.isEmpty ? null : Locale(v)),
                      items: [
                        DropdownMenuItem(value: '', child: Text(l.themeSystem)),
                        const DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        const DropdownMenuItem(
                          value: 'ne',
                          child: Text('नेपाली'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_biometricAvailable)
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: Text(l.enableBiometricUnlock),
                    value: _biometric,
                    onChanged: (v) async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .setBiometricEnabled(v);
                      if (mounted) setState(() => _biometric = v);
                    },
                  ),
                if (AppEnv.isDev)
                  ListTile(
                    key: const Key('profile_dev'),
                    leading: const Icon(Icons.developer_mode),
                    title: Text(l.devMenu),
                    onTap: () => const DevMenuRoute().push<void>(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                ListTile(
                  key: const Key('profile_logout'),
                  leading: const Icon(Icons.logout),
                  title: Text(l.logout),
                  onTap: _logout,
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.version),
                  subtitle: const Text('${AppEnv.flavorName} · 0.1.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
