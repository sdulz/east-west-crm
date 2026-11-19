import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/presentation/follow_up_actions.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-006 (log interaction) and FR-MOB-007 (new follow-up).
class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({
    super.key,
    this.type,
    this.relatedType,
    this.relatedId,
  });
  final ActivityType? type;
  final RelatedType? relatedType;
  final String? relatedId;

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _form = GlobalKey<FormState>();
  final _summary = TextEditingController();
  final _outcome = TextEditingController();
  late ActivityType _type = widget.type ?? ActivityType.call;
  late RelatedType _relatedType = widget.relatedType ?? RelatedType.customer;
  late String? _relatedId = widget.relatedId;
  DateTime? _dueAt;
  final _serverErrors = <String, String>{};
  bool _saving = false;
  late final String _id = uuidV4();

  bool get _lockedRelated => widget.relatedId != null;

  @override
  void dispose() {
    _summary.dispose();
    _outcome.dispose();
    super.dispose();
  }

  bool _isFollowUp(List<ActivityTypeDef> types) =>
      types.where((t) => t.type == _type).firstOrNull?.isFollowUp ?? false;

  Future<void> _save(bool followUp) async {
    setState(_serverErrors.clear);
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    if (followUp && _dueAt == null) {
      setState(() => _serverErrors['dueAt'] = l.required);
      return;
    }
    final me = ref.read(currentUserProvider);
    if (me == null || _relatedId == null) return;
    setState(() => _saving = true);
    final a = Activity(
      id: _id,
      type: _type,
      relatedType: _relatedType,
      relatedId: _relatedId!,
      summary: _summary.text.trim(),
      outcome: followUp || _outcome.text.trim().isEmpty
          ? null
          : _outcome.text.trim(),
      dueAt: followUp ? _dueAt : DateTime.now().toUtc(),
      ownerId: me.id,
      updatedAt: DateTime.now().toUtc(),
    );
    final out = await ref.read(activitySaverProvider.notifier).create(a);
    if (!mounted) return;
    setState(() => _saving = false);
    if (out case SaveRejected(
      failure: ValidationFailure(:final field?, :final message),
    )) {
      setState(() => _serverErrors[field] = message);
      _form.currentState!.validate();
      return;
    }
    if (await showSaveOutcome(context, out) && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final types = ref.watch(activityTypesProvider).valueOrNull ?? const [];
    final followUp = _isFollowUp(types);
    final visibleTypes = widget.type == ActivityType.todo
        ? types.where((t) => t.isFollowUp).toList()
        : types;
    final customers = ref.watch(customerListProvider()).valueOrNull ?? const [];
    final opps = ref.watch(opportunityListProvider()).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(followUp ? l.newFollowUp : l.logInteraction)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (visibleTypes.length > 1)
              Wrap(
                spacing: 8,
                children: [
                  for (final t in visibleTypes)
                    ChoiceChip(
                      key: Key('type_${t.type.name}'),
                      label: Text(t.label),
                      selected: _type == t.type,
                      onSelected: (_) => setState(() => _type = t.type),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            SegmentedButton<RelatedType>(
              segments: [
                ButtonSegment(
                  value: RelatedType.customer,
                  label: Text(l.customer),
                ),
                ButtonSegment(
                  value: RelatedType.opportunity,
                  label: Text(l.opportunity),
                ),
              ],
              selected: {_relatedType},
              onSelectionChanged: _lockedRelated
                  ? null
                  : (s) => setState(() {
                      _relatedType = s.first;
                      _relatedId = null;
                    }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('related_picker'),
              initialValue: _relatedId,
              decoration: InputDecoration(
                labelText: l.relatedTo,
                errorText: _serverErrors['relatedId'],
              ),
              items: _relatedType == RelatedType.customer
                  ? [
                      for (final c in customers)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ]
                  : [
                      for (final o in opps)
                        DropdownMenuItem(value: o.id, child: Text(o.title)),
                    ],
              onChanged: _lockedRelated
                  ? null
                  : (v) => setState(() => _relatedId = v),
              validator: (v) => v == null ? l.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('activity_summary'),
              controller: _summary,
              decoration: InputDecoration(labelText: l.summary),
              maxLines: 2,
              validator: (v) =>
                  _serverErrors['summary'] ??
                  ((v == null || v.trim().isEmpty) ? l.required : null),
            ),
            const SizedBox(height: 12),
            if (followUp)
              ListTile(
                key: const Key('due_picker'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm),
                title: Text(l.dueAt),
                subtitle: Text(
                  _dueAt == null ? l.pickDate : f.dateTime(_dueAt!),
                  style: _serverErrors['dueAt'] != null
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
                ),
                onTap: () async {
                  final d = await pickDateTime(context, ref, initial: _dueAt);
                  if (d != null) setState(() => _dueAt = d);
                },
              )
            else
              TextFormField(
                key: const Key('activity_outcome'),
                controller: _outcome,
                decoration: InputDecoration(labelText: l.outcome),
                maxLines: 3,
              ),
            const SizedBox(height: 24),
            SaveButton(
              key: const Key('activity_save'),
              saving: _saving,
              onPressed: () => _save(followUp),
            ),
          ],
        ),
      ),
    );
  }
}
