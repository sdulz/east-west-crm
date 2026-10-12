import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown after the inactivity timeout. Re-auth with biometrics or password.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    final auth = ref.read(authControllerProvider.notifier);
    if (!await auth.isBiometricEnabled()) return;
    final bio = ref.read(biometricAuthProvider);
    if (!mounted) return;
    final reason = context.l10n.biometricReason;
    if (await bio.isAvailable() && await bio.authenticate(reason)) {
      ref.read(appLockProvider.notifier).unlock();
    }
  }

  Future<void> _withPassword() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    final r = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: user.email,
          password: _password.text,
          rememberMe: await ref
              .read(authControllerProvider.notifier)
              .hasRememberedToken,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _wrong = r is Err;
    });
    if (r.isOk) ref.read(appLockProvider.notifier).unlock();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: LeadingGlyph(icon: Icons.lock_outline, size: 72),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.sessionLocked,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l.password,
                      errorText: _wrong ? l.loginInvalid : null,
                    ),
                    onSubmitted: (_) => _withPassword(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _withPassword,
                    child: Text(l.unlock),
                  ),
                  TextButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l.unlockWithBiometrics),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      ref.read(appLockProvider.notifier).unlock();
                    },
                    child: Text(l.logout),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
