import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/handover/application/user_directory_controllers.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-009. The confirmed owner comes from the repository response.
Future<void> showHandoverSheet(BuildContext context, Opportunity o) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => HandoverSheet(opportunity: o),
    );

class HandoverSheet extends ConsumerStatefulWidget {
  const HandoverSheet({required this.opportunity, super.key});
  final Opportunity opportunity;

  @override
  ConsumerState<HandoverSheet> createState() => _HandoverSheetState();
}

class _HandoverSheetState extends ConsumerState<HandoverSheet> {
  String? _selected;
  bool _saving = false;

  Future<void> _confirm(List<AppUser> users) async {
    final id = _selected;
    if (id == null) return;
    setState(() => _saving = true);
    final out = await ref
        .read(opportunitySaverProvider.notifier)
        .reassign(widget.opportunity, newOwnerId: id);
    if (!mounted) return;
    setState(() => _saving = false);
    final confirmedName = switch (out) {
      SaveSuccess(:final value) =>
        users.where((u) => u.id == value.ownerId).firstOrNull?.name ??
            value.ownerId,
      _ => null,
    };
    final pop = await showSaveOutcome(
      context,
      out,
      successMessage: confirmedName == null
          ? null
          : context.l10n.handoverConfirmed(confirmedName),
      onReloadLatest: () async =>
          ref.invalidate(opportunityDetailProvider(widget.opportunity.id)),
    );
    if (pop && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final users = ref.watch(assignableUsersProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.handoverTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: AsyncView<List<AppUser>>(
                value: users,
                onRetry: () => ref.invalidate(assignableUsersProvider),
                loading: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                data: (list) => RadioGroup<String>(
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final u in list)
                        RadioListTile<String>(
                          key: Key('handover_user_${u.id}'),
                          value: u.id,
                          enabled: u.id != widget.opportunity.ownerId,
                          title: Text(u.name),
                          subtitle: Text(u.email),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SaveButton(
              key: const Key('handover_confirm'),
              saving: _saving,
              label: l.handover,
              onPressed: _selected == null || users.valueOrNull == null
                  ? null
                  : () => _confirm(users.valueOrNull!),
            ),
          ],
        ),
      ),
    );
  }
}
