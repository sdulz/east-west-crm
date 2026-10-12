import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/features/activities/presentation/follow_up_actions.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:field_crm/features/pipeline/application/pipeline_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-005 create / edit. Stage and owner change through their own flows.
class OpportunityFormScreen extends ConsumerWidget {
  const OpportunityFormScreen({super.key, this.id, this.customerId});
  final String? id;
  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (id == null) {
      return _OpportunityForm(initial: null, customerId: customerId);
    }
    final o = ref.watch(opportunityDetailProvider(id!));
    return AsyncView<Opportunity>(
      value: o,
      onRetry: () => ref.invalidate(opportunityDetailProvider(id!)),
      data: (o) => _OpportunityForm(initial: o, key: ValueKey(o.updatedAt)),
    );
  }
}

class _OpportunityForm extends ConsumerStatefulWidget {
  const _OpportunityForm({required this.initial, super.key, this.customerId});
  final Opportunity? initial;
  final String? customerId;

  @override
  ConsumerState<_OpportunityForm> createState() => _OpportunityFormState();
}

class _OpportunityFormState extends ConsumerState<_OpportunityForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _revenue = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.expectedRevenue.toStringAsFixed(0),
  );
  late final _probability = TextEditingController(
    text: '${widget.initial?.probability ?? 10}',
  );
  late final _nextSummary = TextEditingController(
    text: widget.initial?.nextActionSummary,
  );
  late String? _customerId = widget.initial?.customerId ?? widget.customerId;
  late String? _stageId = widget.initial?.stageId;
  late DateTime? _nextAt = widget.initial?.nextActionAt;
  late final String _id = widget.initial?.id ?? uuidV4();
  final _serverErrors = <String, String>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_title, _revenue, _probability, _nextSummary]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(_serverErrors.clear);
    if (!_form.currentState!.validate()) return;
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    setState(() => _saving = true);
    final isNew = widget.initial == null;
    final o = Opportunity(
      id: _id,
      title: _title.text.trim(),
      customerId: _customerId ?? '',
      stageId: _stageId ?? '',
      ownerId: widget.initial?.ownerId ?? me.id,
      teamId: widget.initial?.teamId ?? me.teamId,
      expectedRevenue: double.tryParse(_revenue.text) ?? 0,
      probability: int.tryParse(_probability.text) ?? 0,
      nextActionAt: _nextAt,
      nextActionSummary: _nextSummary.text.trim().isEmpty
          ? null
          : _nextSummary.text.trim(),
      updatedAt: widget.initial?.updatedAt ?? DateTime.now().toUtc(),
    );
    final out = await ref
        .read(opportunitySaverProvider.notifier)
        .save(o, isNew: isNew, expectedUpdatedAt: widget.initial?.updatedAt);
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
          ref.invalidate(opportunityDetailProvider(widget.initial!.id)),
    );
    if (pop && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final customers = ref.watch(customerListProvider()).value ?? const [];
    final stages = ref.watch(stagesProvider).value ?? const [];
    final isNew = widget.initial == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? l.newOpportunity : l.editOpportunity)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('opportunity_title'),
              controller: _title,
              decoration: InputDecoration(labelText: l.title),
              validator: (v) =>
                  _serverErrors['title'] ??
                  ((v == null || v.trim().isEmpty) ? l.required : null),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('opportunity_customer'),
              initialValue: _customerId,
              decoration: InputDecoration(
                labelText: l.customer,
                errorText: _serverErrors['customerId'],
              ),
              items: [
                for (final c in customers)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: isNew ? (v) => setState(() => _customerId = v) : null,
              validator: (v) => v == null ? l.selectCustomer : null,
            ),
            const SizedBox(height: 12),
            if (isNew)
              DropdownButtonFormField<String>(
                key: const Key('opportunity_stage'),
                initialValue: _stageId ?? stages.firstOrNull?.id,
                decoration: InputDecoration(
                  labelText: l.stage,
                  errorText: _serverErrors['stageId'],
                ),
                items: [
                  for (final s in stages)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setState(() => _stageId = v),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('opportunity_revenue'),
                    controller: _revenue,
                    decoration: InputDecoration(
                      labelText: l.expectedRevenue,
                      errorText: _serverErrors['expectedRevenue'],
                      helperText: f.money(double.tryParse(_revenue.text) ?? 0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        (v != null &&
                            v.isNotEmpty &&
                            double.tryParse(v) == null)
                        ? l.required
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _probability,
                    decoration: InputDecoration(
                      labelText: '${l.probability} %',
                      errorText: _serverErrors['probability'],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 0 || n > 100)
                          ? l.required
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(l.nextAction),
              subtitle: Text(
                _nextAt == null ? l.nextActionNone : f.dateTime(_nextAt!),
              ),
              trailing: _nextAt == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l.none,
                      onPressed: () => setState(() => _nextAt = null),
                    ),
              onTap: () async {
                final d = await pickDateTime(context, ref, initial: _nextAt);
                if (d != null) setState(() => _nextAt = d);
              },
            ),
            TextFormField(
              controller: _nextSummary,
              decoration: InputDecoration(labelText: l.summary),
            ),
            const SizedBox(height: 24),
            SaveButton(
              key: const Key('opportunity_save'),
              saving: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
