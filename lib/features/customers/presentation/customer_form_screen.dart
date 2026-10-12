import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-004 create / edit. Inline validation plus verbatim server messages.
class CustomerFormScreen extends ConsumerWidget {
  const CustomerFormScreen({super.key, this.id});
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) return const _CustomerForm(initial: null);
    final c = ref.watch(customerDetailProvider(id!));
    return AsyncView<Customer>(
      value: c,
      onRetry: () => ref.invalidate(customerDetailProvider(id!)),
      data: (c) => _CustomerForm(initial: c, key: ValueKey(c.updatedAt)),
    );
  }
}

class _CustomerForm extends ConsumerStatefulWidget {
  const _CustomerForm({required this.initial, super.key});
  final Customer? initial;

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _email = TextEditingController(text: widget.initial?.email);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _city = TextEditingController(text: widget.initial?.city);
  late final _country = TextEditingController(text: widget.initial?.country);
  late final _taxId = TextEditingController(text: widget.initial?.taxId);
  late bool _isCompany = widget.initial?.isCompany ?? true;
  late String? _parentId = widget.initial?.parentId;
  // Client-generated once so retries of a create are idempotent.
  late final String _id = widget.initial?.id ?? uuidV4();
  final _serverErrors = <String, String>{};
  bool _saving = false;

  static final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _phoneRe = RegExp(r'^\+?[0-9][0-9 -]{6,17}[0-9]$');

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _address,
      _city,
      _country,
      _taxId,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Customer _build() => Customer(
    id: _id,
    name: _name.text.trim(),
    isCompany: _isCompany,
    parentId: _parentId,
    phone: _opt(_phone),
    email: _opt(_email),
    address: _opt(_address),
    city: _opt(_city),
    country: _opt(_country),
    taxId: _opt(_taxId),
    updatedAt: widget.initial?.updatedAt ?? DateTime.now().toUtc(),
  );

  Future<void> _save() async {
    setState(_serverErrors.clear);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final isNew = widget.initial == null;
    final out = await ref
        .read(customerSaverProvider.notifier)
        .save(
          _build(),
          isNew: isNew,
          expectedUpdatedAt: widget.initial?.updatedAt,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (out case SaveRejected(
      failure: ValidationFailure(:final field?, :final message),
    )) {
      setState(() => _serverErrors[field] = message);
      _form.currentState!.validate();
      return;
    }
    final pop = await showSaveOutcome(
      context,
      out,
      onReloadLatest: () async =>
          ref.invalidate(customerDetailProvider(widget.initial!.id)),
    );
    if (pop && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final companies = (ref.watch(customerListProvider()).value ?? const [])
        .where((c) => c.isCompany && c.id != _id)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l.newCustomer : l.editCustomer),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('customer_name'),
              controller: _name,
              decoration: InputDecoration(labelText: l.name),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  _serverErrors['name'] ??
                  ((v == null || v.trim().isEmpty) ? l.required : null),
            ),
            SwitchListTile(
              title: Text(l.isCompany),
              value: _isCompany,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _isCompany = v),
            ),
            DropdownButtonFormField<String?>(
              initialValue: _parentId,
              decoration: InputDecoration(
                labelText: l.parentCompany,
                errorText: _serverErrors['parentId'],
              ),
              items: [
                DropdownMenuItem(child: Text(l.none)),
                for (final c in companies)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('customer_phone'),
              controller: _phone,
              decoration: InputDecoration(labelText: l.phone),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  _serverErrors['phone'] ??
                  ((v != null &&
                          v.trim().isNotEmpty &&
                          !_phoneRe.hasMatch(v.trim()))
                      ? l.invalidPhone
                      : null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('customer_email'),
              controller: _email,
              decoration: InputDecoration(labelText: l.email),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  _serverErrors['email'] ??
                  ((v != null &&
                          v.trim().isNotEmpty &&
                          !_emailRe.hasMatch(v.trim()))
                      ? l.invalidEmail
                      : null),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: l.address),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    decoration: InputDecoration(labelText: l.city),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _country,
                    decoration: InputDecoration(labelText: l.country),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxId,
              decoration: InputDecoration(labelText: l.taxId),
            ),
            const SizedBox(height: 24),
            SaveButton(
              key: const Key('customer_save'),
              saving: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
