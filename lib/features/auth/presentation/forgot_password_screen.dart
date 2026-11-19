import 'package:field_crm/app/env.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Two steps: request a code for an email, then set a new password with it.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _codeError;

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _requestCode() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final r = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_email.text);
    if (!mounted) return;
    setState(() => _busy = false);
    final l = context.l10n;
    switch (r) {
      case Ok(:final value):
        if (value == null) {
          _snack(l.resetCodeSent);
          Navigator.pop(context);
        } else {
          setState(() => _codeSent = true);
          _snack(
            AppEnv.isDev ? l.resetCodeDev(value) : l.resetCodeSent,
          );
        }
      case Err(:final error):
        _snack(failureMessage(context, error));
    }
  }

  Future<void> _reset() async {
    setState(() => _codeError = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final r = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          email: _email.text,
          code: _code.text,
          newPassword: _password.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    final l = context.l10n;
    switch (r) {
      case Ok():
        _snack(l.passwordReset);
        Navigator.pop(context);
      case Err(error: ValidationFailure(field: 'code')):
        setState(() => _codeError = l.invalidResetCode);
        _form.currentState!.validate();
      case Err(:final error):
        _snack(failureMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.resetPassword)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: LeadingGlyph(icon: Icons.lock_reset, size: 72),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('reset_email'),
                    controller: _email,
                    enabled: !_codeSent,
                    decoration: InputDecoration(labelText: l.email),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? l.invalidEmail : null,
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('reset_code'),
                      controller: _code,
                      decoration: InputDecoration(labelText: l.resetCode),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          _codeError ??
                          ((v == null || v.trim().isEmpty) ? l.required : null),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('reset_password'),
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.newPassword),
                      validator: (v) => (v == null || v.length < 8)
                          ? l.passwordTooShort
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('reset_confirm'),
                      controller: _confirm,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.confirmPassword),
                      onFieldSubmitted: (_) => _reset(),
                      validator: (v) =>
                          v != _password.text ? l.passwordsDoNotMatch : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('reset_submit'),
                    onPressed: _busy
                        ? null
                        : (_codeSent ? _reset : _requestCode),
                    child: Text(_codeSent ? l.resetPassword : l.sendResetCode),
                  ),
                  if (_codeSent)
                    TextButton(
                      onPressed: _busy ? null : _requestCode,
                      child: Text(l.sendResetCode),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.backToLogin),
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
