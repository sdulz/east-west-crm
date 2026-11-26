import 'dart:async';

import 'package:field_crm/app/env.dart';
import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/widgets/app_logo.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/auth/data/mock_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// FR-MOB-001.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;
  bool _busy = false;
  bool _canBiometric = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final r = await Future.wait([
      ref.read(authControllerProvider.notifier).hasRememberedToken,
      ref.read(authControllerProvider.notifier).isBiometricEnabled(),
    ]);
    if (mounted) setState(() => _canBiometric = r[0] && r[1]);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _email.text.trim(),
          password: _password.text,
          rememberMe: _remember,
        );
    if (!mounted) return;
    if (r case Ok()) {
      TextInput.finishAutofillContext();
    }
    final l = context.l10n;
    setState(() {
      _busy = false;
      _error = switch (r) {
        Ok() => null,
        Err(
          error: ValidationFailure(message: MockAuthRepository.inactiveAccount),
        ) =>
          l.loginInactive,
        Err(
          error: ValidationFailure(
            message: MockAuthRepository.invalidCredentials,
          ),
        ) =>
          l.loginInvalid,
        Err(error: ValidationFailure(:final message)) =>
          message.isNotEmpty ? message : l.loginInvalid,
        Err(:final error) => failureMessage(context, error),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 180)),
                      const SizedBox(height: 16),
                      Text(
                        AppEnv.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const Key('login_email'),
                        controller: _email,
                        decoration: InputDecoration(labelText: l.email),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? l.invalidEmail
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('login_password'),
                        controller: _password,
                        decoration: InputDecoration(labelText: l.password),
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l.required : null,
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        value: _remember,
                        onChanged: (v) => setState(() => _remember = v ?? true),
                        title: Text(l.rememberMe),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            key: const Key('login_error'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      FilledButton(
                        key: const Key('login_submit'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l.login),
                      ),
                      TextButton(
                        key: const Key('login_forgot'),
                        onPressed: () =>
                            const ForgotPasswordRoute().push<void>(context),
                        child: Text(l.forgotPassword),
                      ),
                      if (_canBiometric)
                        TextButton.icon(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .retryRestore(),
                          icon: const Icon(Icons.fingerprint),
                          label: Text(l.unlockWithBiometrics),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
