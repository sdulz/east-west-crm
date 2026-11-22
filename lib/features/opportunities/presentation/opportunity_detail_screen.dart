import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/contact/contact_actions.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/labeled_field.dart';
import 'package:field_crm/core/widgets/pending_badge.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/presentation/activity_tile.dart';
import 'package:field_crm/features/activities/presentation/notes_panel.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/handover/application/user_directory_controllers.dart';
import 'package:field_crm/features/handover/presentation/handover_sheet.dart';
import 'package:field_crm/features/history/presentation/history_timeline.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pipeline/application/pipeline_controllers.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:field_crm/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:field_crm/features/quotations/presentation/quotation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-005 / 008 / 009 / 010.
class OpportunityDetailScreen extends ConsumerStatefulWidget {
  const OpportunityDetailScreen({
    required this.id,
    super.key,
    this.embedded = false,
  });
  final String id;
  final bool embedded;

  @override
  ConsumerState<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState
    extends ConsumerState<OpportunityDetailScreen> {
  bool _changingStage = false;

  Future<void> _changeStage(Opportunity o, PipelineStage to) async {
    setState(() => _changingStage = true);
    final out = await ref
        .read(opportunitySaverProvider.notifier)
        .changeStage(o, toStageId: to.id);
    if (!mounted) return;
    setState(() => _changingStage = false);
    await showSaveOutcome(
      context,
      out,
      successMessage: context.l10n.stageMoved(to.name),
      onReloadLatest: () async =>
          ref.invalidate(opportunityDetailProvider(widget.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final id = widget.id;
    final opp = ref.watch(opportunityDetailProvider(id));
    final perms = ref.watch(permissionsProvider);
    final stages = ref.watch(stagesProvider).valueOrNull ?? const <PipelineStage>[];
    final f = ref.watch(formattersProvider);
    final users = ref.watch(userNamesProvider).valueOrNull ?? const {};
    final customers = ref.watch(customerNamesProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(opp.valueOrNull?.title ?? l.opportunity),
        actions: [
          if (perms.canEditOpportunity && opp.hasValue)
            IconButton(
              key: const Key('opportunity_edit'),
              tooltip: l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => OpportunityEditRoute(id: id).push<void>(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'opp_fab_$id',
        tooltip: l.quickAdd,
        onPressed: () => showQuickAdd(
          context,
          relatedType: RelatedType.opportunity,
          relatedId: id,
          customerId: opp.valueOrNull?.customerId,
        ),
        child: const Icon(Icons.add),
      ),
      body: AsyncView<Opportunity>(
        value: opp,
        onRetry: () => ref.invalidate(opportunityDetailProvider(id)),
        data: (o) {
          final stage = stages.where((s) => s.id == o.stageId).firstOrNull;
          final phone = ref
              .watch(customerDetailProvider(o.customerId))
              .valueOrNull
              ?.phone;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          f.money(o.expectedRevenue),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PendingBadge(targetId: o.id),
                ],
              ),
              const SizedBox(height: 20),
              if (phone != null) ...[
                ContactButtons(phone: phone),
                const SizedBox(height: 12),
              ],
              Panel(
                child: Column(
                  children: [
                    LabeledField(
                      label: l.customer,
                      value: customers[o.customerId] ?? o.customerId,
                      trailing: IconButton(
                        tooltip: l.view,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        onPressed: () =>
                            CustomerDetailRoute(id: o.customerId)
                                .push<void>(context),
                      ),
                    ),
                    LabeledField(
                      label: l.stage,
                      value: stage?.name ?? o.stageId,
                      trailing: perms.canChangeStage && stage != null
                          ? _StagePicker(
                              key: const Key('stage_picker'),
                              current: stage,
                              stages: stages,
                              busy: _changingStage,
                              onPick: (to) => _changeStage(o, to),
                            )
                          : null,
                    ),
                    LabeledField(
                      key: const Key('owner_field'),
                      label: l.owner,
                      value: users[o.ownerId] ?? o.ownerId,
                      trailing: perms.canReassign
                          ? TextButton.icon(
                              key: const Key('handover_button'),
                              icon: const Icon(Icons.swap_horiz),
                              label: Text(l.handover),
                              onPressed: () => showHandoverSheet(context, o),
                            )
                          : null,
                    ),
                    LabeledField(
                      label: l.expectedRevenue,
                      value: f.money(o.expectedRevenue),
                    ),
                    LabeledField(
                      label: l.probability,
                      value: '${o.probability}%',
                    ),
                    LabeledField(
                      label: l.nextAction,
                      value: o.nextActionAt == null
                          ? l.nextActionNone
                          : [
                              f.dateTime(o.nextActionAt!),
                              ?o.nextActionSummary,
                            ].join(' · '),
                    ),
                  ],
                ),
              ),
              SectionHeader(l.internalNotes),
              NotesPanel(relatedType: RelatedType.opportunity, relatedId: id),
              SectionHeader(
                l.quotations,
                trailing: perms.canCreateOpportunity
                    ? TextButton.icon(
                        key: const Key('opportunity_new_quotation'),
                        onPressed: () => QuotationNewRoute(
                          customerId: o.customerId,
                          opportunityId: id,
                        ).push<void>(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.newQuotation),
                      )
                    : null,
              ),
              Panel(child: QuotationList(opportunityId: id)),
              SectionHeader(l.activities),
              Panel(child: _OpportunityActivities(opportunityId: id)),
              SectionHeader(l.history),
              Panel(
                child: HistoryTimeline(type: RelatedType.opportunity, id: id),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// FR-MOB-008: only allowed transitions are enabled.
class _StagePicker extends StatelessWidget {
  const _StagePicker({
    required this.current,
    required this.stages,
    required this.busy,
    required this.onPick,
    super.key,
  });
  final PipelineStage current;
  final List<PipelineStage> stages;
  final bool busy;
  final ValueChanged<PipelineStage> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (busy) {
      return const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return PopupMenuButton<PipelineStage>(
      tooltip: l.changeStage,
      icon: const Icon(Icons.swap_vert),
      onSelected: onPick,
      itemBuilder: (_) => [
        for (final s in stages)
          PopupMenuItem(
            key: Key('stage_option_${s.id}'),
            value: s,
            enabled: s.id != current.id && current.canMoveTo(s.id),
            child: Text(s.name),
          ),
      ],
    );
  }
}

class _OpportunityActivities extends ConsumerWidget {
  const _OpportunityActivities({required this.opportunityId});
  final String opportunityId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ActivityFilter(
      relatedType: RelatedType.opportunity,
      relatedId: opportunityId,
    );
    final acts = ref.watch(activityListProvider(filter));
    return AsyncView(
      value: acts,
      onRetry: () => ref.invalidate(activityListProvider(filter)),
      loading: const LinearProgressIndicator(),
      isEmpty: (v) => v.every((a) => a.type == ActivityType.note),
      data: (items) => Column(
        children: [
          for (final a in items.reversed)
            if (a.type != ActivityType.note) ActivityTile(activity: a),
        ],
      ),
    );
  }
}
