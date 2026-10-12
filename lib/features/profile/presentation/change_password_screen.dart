import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _serverErrors = <String, String>{};
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(_serverErrors.clear);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final r = await ref
        .read(authControllerProvider.notifier)
        .changePassword(current: _current.text, next: _next.text);
    if (!mounted) return;
    setState(() => _saving = false);
    final l = context.l10n;
    switch (r) {
      case Ok():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.passwordChanged)));
        Navigator.pop(context);
      case Err(error: ValidationFailure(:final field?, :final message)):
        setState(() => _serverErrors[field] = message);
        _form.currentState!.validate();
      case Err(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(context, error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.changePassword)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('password_current'),
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(labelText: l.currentPassword),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  _serverErrors['current'] ??
                  ((v == null || v.isEmpty) ? l.required : null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('password_new'),
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: l.newPassword),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  _serverErrors['next'] ??
                  ((v == null || v.length < 8) ? l.passwordTooShort : null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('password_confirm'),
              controller: _confirm,
              obscureText: true,
              decoration: InputDecoration(labelText: l.confirmPassword),
              onFieldSubmitted: (_) => _save(),
              validator: (v) => v != _next.text ? l.passwordsDoNotMatch : null,
            ),
            const SizedBox(height: 24),
            SaveButton(
              key: const Key('password_save'),
              saving: _saving,
              onPressed: _save,
              label: l.changePassword,
            ),
          ],
        ),
      ),
    );
  }
}
