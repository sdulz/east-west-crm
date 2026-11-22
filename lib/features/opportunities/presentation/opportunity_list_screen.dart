import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/list_detail_layout.dart';
import 'package:field_crm/core/widgets/pending_badge.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/handover/application/user_directory_controllers.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/opportunities/presentation/opportunity_detail_screen.dart';
import 'package:field_crm/features/pipeline/application/pipeline_controllers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// CRM tab: opportunity list with a link to the pipeline kanban.
class OpportunityListScreen extends ConsumerStatefulWidget {
  const OpportunityListScreen({super.key});

  @override
  ConsumerState<OpportunityListScreen> createState() =>
      _OpportunityListScreenState();
}

class _OpportunityListScreenState extends ConsumerState<OpportunityListScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = ref.watch(opportunityListProvider());
    final perms = ref.watch(permissionsProvider);
    final wide = ListDetailLayout.isWide(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.opportunities),
        actions: [
          IconButton(
            key: const Key('open_pipeline'),
            tooltip: l.pipeline,
            icon: const Icon(Icons.view_kanban_outlined),
            onPressed: () => const PipelineRoute().push<void>(context),
          ),
          if (perms.canCreateOpportunity)
            IconButton(
              key: const Key('opportunity_add'),
              tooltip: l.newOpportunity,
              icon: const Icon(Icons.add_business_outlined),
              onPressed: () => const OpportunityNewRoute().push<void>(context),
            ),
        ],
      ),
      body: ListDetailLayout(
        list: RefreshIndicator(
          onRefresh: () => ref.refresh(opportunityListProvider().future),
          child: AsyncView<List<Opportunity>>(
            value: list,
            onRetry: () => ref.invalidate(opportunityListProvider()),
            isEmpty: (v) => v.isEmpty,
            data: (items) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
              itemCount: items.length,
              itemBuilder: (_, i) => OpportunityRow(
                o: items[i],
                selected: wide && items[i].id == _selectedId,
                onTap: () => wide
                    ? setState(() => _selectedId = items[i].id)
                    : OpportunityDetailRoute(id: items[i].id)
                          .push<void>(context),
              ),
            ),
          ),
        ),
        detail: _selectedId == null
            ? null
            : OpportunityDetailScreen(id: _selectedId!, embedded: true),
      ),
    );
  }
}

class OpportunityRow extends ConsumerWidget {
  const OpportunityRow({
    required this.o,
    required this.onTap,
    super.key,
    this.selected = false,
  });
  final Opportunity o;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(formattersProvider);
    final stage = ref.watch(stagesByIdProvider).valueOrNull?[o.stageId];
    final customer =
        ref.watch(customerNamesProvider).valueOrNull?[o.customerId];
    final owner = ref.watch(userNamesProvider).valueOrNull?[o.ownerId];
    return ListTile(
      key: Key('opportunity_${o.id}'),
      selected: selected,
      leading: const LeadingGlyph(icon: Icons.work_outline),
      title: Text(o.title),
      subtitle: Text(
        [
          ?customer,
          stage?.name ?? o.stageId,
          f.money(o.expectedRevenue),
          ?owner,
        ].join(' · '),
      ),
      trailing: PendingBadge(targetId: o.id),
      onTap: onTap,
    );
  }
}
