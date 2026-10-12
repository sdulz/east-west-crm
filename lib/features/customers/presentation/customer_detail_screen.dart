import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/contact/contact_actions.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/labeled_field.dart';
import 'package:field_crm/core/widgets/pending_badge.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/presentation/activity_tile.dart';
import 'package:field_crm/features/activities/presentation/notes_panel.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/history/presentation/history_timeline.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/pipeline/application/pipeline_controllers.dart';
import 'package:field_crm/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:field_crm/features/quotations/presentation/quotation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-004 detail with opportunities, activities and history.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({
    required this.id,
    super.key,
    this.embedded = false,
  });
  final String id;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final customer = ref.watch(customerDetailProvider(id));
    final perms = ref.watch(permissionsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !embedded,
        title: Text(customer.value?.name ?? l.customer),
        actions: [
          if (perms.canEditCustomer && customer.hasValue)
            IconButton(
              key: const Key('customer_edit'),
              tooltip: l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => CustomerEditRoute(id: id).push<void>(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'customer_fab_$id',
        tooltip: l.quickAdd,
        onPressed: () => showQuickAdd(
          context,
          relatedType: RelatedType.customer,
          relatedId: id,
        ),
        child: const Icon(Icons.add),
      ),
      body: AsyncView<Customer>(
        value: customer,
        onRetry: () => ref.invalidate(customerDetailProvider(id)),
        data: (c) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LeadingGlyph(
                  icon: c.isCompany ? Icons.business : null,
                  text: c.isCompany ? null : c.name[0],
                  size: 56,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (c.city != null)
                        Text(
                          c.city!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                PendingBadge(targetId: c.id),
              ],
            ),
            const SizedBox(height: 20),
            if (c.phone != null) ...[
              ContactButtons(phone: c.phone!),
              const SizedBox(height: 12),
            ],
            Panel(
              child: Column(
                children: [
                  if (c.parentId != null) _ParentRow(parentId: c.parentId!),
                  if (c.phone != null)
                    LabeledField(label: l.phone, value: c.phone!),
                  if (c.email != null)
                    LabeledField(label: l.email, value: c.email!),
                  if (c.address != null || c.city != null)
                    LabeledField(
                      label: l.address,
                      value: [
                        c.address,
                        c.city,
                        c.country,
                      ].whereType<String>().join(', '),
                    ),
                  if (c.taxId != null)
                    LabeledField(label: l.taxId, value: c.taxId!),
                ],
              ),
            ),
            SectionHeader(l.opportunities),
            Panel(child: _CustomerOpportunities(customerId: id)),
            SectionHeader(l.internalNotes),
            NotesPanel(relatedType: RelatedType.customer, relatedId: id),
            SectionHeader(
              l.quotations,
              trailing: perms.canCreateOpportunity
                  ? TextButton.icon(
                      key: const Key('customer_new_quotation'),
                      onPressed: () =>
                          QuotationNewRoute(customerId: id).push<void>(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.newQuotation),
                    )
                  : null,
            ),
            Panel(child: QuotationList(customerId: id)),
            SectionHeader(l.invoices),
            Panel(child: InvoiceList(customerId: id)),
            SectionHeader(l.activities),
            Panel(child: _CustomerActivities(customerId: id)),
            SectionHeader(l.history),
            Panel(
              child: HistoryTimeline(type: RelatedType.customer, id: id),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentRow extends ConsumerWidget {
  const _ParentRow({required this.parentId});
  final String parentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(customerNamesProvider).value?[parentId] ?? parentId;
    return LabeledField(
      label: context.l10n.parentCompany,
      value: name,
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new, size: 18),
        tooltip: context.l10n.view,
        onPressed: () => CustomerDetailRoute(id: parentId).push<void>(context),
      ),
    );
  }
}

class _CustomerOpportunities extends ConsumerWidget {
  const _CustomerOpportunities({required this.customerId});
  final String customerId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opps = ref.watch(opportunityListProvider(customerId: customerId));
    final stages = ref.watch(stagesByIdProvider).value ?? const {};
    final f = ref.watch(formattersProvider);
    return AsyncView(
      value: opps,
      onRetry: () =>
          ref.invalidate(opportunityListProvider(customerId: customerId)),
      isEmpty: (v) => v.isEmpty,
      loading: const LinearProgressIndicator(),
      data: (items) => Column(
        children: [
          for (final o in items)
            ListTile(
              leading: const LeadingGlyph(icon: Icons.work_outline),
              title: Text(o.title),
              subtitle: Text(
                '${stages[o.stageId]?.name ?? o.stageId} · '
                '${f.money(o.expectedRevenue)}',
              ),
              trailing: PendingBadge(targetId: o.id),
              onTap: () => OpportunityDetailRoute(id: o.id).push<void>(context),
            ),
        ],
      ),
    );
  }
}

class _CustomerActivities extends ConsumerWidget {
  const _CustomerActivities({required this.customerId});
  final String customerId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ActivityFilter(
      relatedType: RelatedType.customer,
      relatedId: customerId,
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
