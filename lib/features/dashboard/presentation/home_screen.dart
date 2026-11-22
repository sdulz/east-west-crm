import 'dart:async';

import 'package:field_crm/app/providers.dart';
import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/activities/application/reminder_sync.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/presentation/activity_tile.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/dashboard/application/dashboard_controller.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_summary.dart';
import 'package:field_crm/features/dashboard/presentation/dashboard_charts.dart';
import 'package:field_crm/features/notifications/application/notification_controllers.dart';
import 'package:field_crm/features/opportunities/application/assignment_watcher.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pending/application/pending_queue_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Group { today, upcoming, overdue, noFollowUp }

/// FR-MOB-002.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _Group _selected = _Group.today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final summary = ref.watch(dashboardControllerProvider);
    final newlyAssigned = ref.watch(assignmentWatcherProvider);
    final pendingCount = ref.watch(pendingCountProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final user = ref.watch(currentUserProvider);
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);

    ref.listen(dashboardControllerProvider, (_, next) {
      final s = next.valueOrNull;
      if (s == null) return;
      unawaited(
        ref
            .read(reminderSyncProvider.notifier)
            .sync(
              [...s.today, ...s.upcoming],
              title: l.reminderTitle,
              body: l.reminderBody,
            ),
      );
    });
    ref.listen(opportunityListProvider(), (_, next) {
      final list = next.valueOrNull;
      final me = ref.read(currentUserIdProvider);
      if (list != null && me != null) {
        ref
            .read(assignmentWatcherProvider.notifier)
            .check(list.where((o) => o.ownerId == me).toList());
      }
    });
    ref.watch(opportunityListProvider());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user == null ? l.navHome : l.homeGreeting(user.name.split(' ').first),
        ),
        actions: [
          IconButton(
            tooltip: l.search,
            icon: const Icon(Icons.search),
            onPressed: () => const SearchRoute().push<void>(context),
          ),
          IconButton(
            key: const Key('home_notifications'),
            tooltip: l.notifications,
            icon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => const NotificationsRoute().push<void>(context),
          ),
          if (pendingCount > 0)
            IconButton(
              tooltip: l.pendingCenter,
              icon: Badge.count(
                count: pendingCount,
                child: const Icon(Icons.sync_problem),
              ),
              onPressed: () => const PendingRoute().push<void>(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dashboardControllerProvider.notifier).refresh(),
        child: AsyncView<DashboardSummary>(
          value: summary,
          onRetry: () => ref.invalidate(dashboardControllerProvider),
          data: (s) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  f.date(ref.read(clockProvider).now()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (newlyAssigned.isNotEmpty)
                _AssignmentBanner(items: newlyAssigned),
              Panel(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _StatCell(
                      label: l.today,
                      count: s.today.length,
                      selected: _selected == _Group.today,
                      onTap: () => setState(() => _selected = _Group.today),
                    ),
                    _StatCell(
                      label: l.upcoming,
                      count: s.upcoming.length,
                      selected: _selected == _Group.upcoming,
                      onTap: () => setState(() => _selected = _Group.upcoming),
                    ),
                    _StatCell(
                      label: l.overdue,
                      count: s.overdue.length,
                      selected: _selected == _Group.overdue,
                      danger: s.overdue.isNotEmpty,
                      onTap: () => setState(() => _selected = _Group.overdue),
                    ),
                    _StatCell(
                      label: l.noFollowUp,
                      count: s.noFollowUp.length,
                      selected: _selected == _Group.noFollowUp,
                      onTap: () =>
                          setState(() => _selected = _Group.noFollowUp),
                    ),
                  ],
                ),
              ),
              SectionHeader(switch (_selected) {
                _Group.today => l.today,
                _Group.upcoming => l.upcoming,
                _Group.overdue => l.overdue,
                _Group.noFollowUp => l.noFollowUp,
              }),
              Panel(child: Column(children: _groupItems(s))),
              SectionHeader(l.pipeline),
              const PipelineCard(),
              SectionHeader(l.activities),
              const WeekActivityCard(),
              SectionHeader(l.invoices),
              const InvoicesCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _groupItems(DashboardSummary s) {
    final l = context.l10n;
    final empty = [
      Padding(padding: const EdgeInsets.all(16), child: Text(l.emptyList)),
    ];
    if (_selected == _Group.noFollowUp) {
      if (s.noFollowUp.isEmpty) return empty;
      return s.noFollowUp.map(_OpportunityRow.new).toList();
    }
    final items = switch (_selected) {
      _Group.today => s.today,
      _Group.upcoming => s.upcoming,
      _ => s.overdue,
    };
    if (items.isEmpty) return empty;
    return items.map((a) => ActivityTile(activity: a)).toList();
  }
}

/// One cell of the stat strip: count over label, tonal when selected.
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });
  final String label;
  final int count;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = !selected
        ? Colors.transparent
        : danger
        ? scheme.errorContainer
        : scheme.primaryContainer;
    final fg = danger
        ? scheme.error
        : selected
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final muted = selected && !danger
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            button: true,
            selected: selected,
            label: context.l10n.dashboardCountCard(label, count),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: muted),
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

class _OpportunityRow extends ConsumerWidget {
  const _OpportunityRow(this.o);
  final Opportunity o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(formattersProvider);
    final customerName =
        ref
            .watch(crmApiClientProvider)
            .documentNames['${RelatedType.customer.name}:${o.customerId}'] ??
        ref.watch(customerNamesProvider).valueOrNull?[o.customerId];
    return ListTile(
      leading: const LeadingGlyph(icon: Icons.work_outline),
      title: Text(o.title),
      subtitle: Text(
        [
          if (customerName != null && customerName.isNotEmpty) customerName,
          f.money(o.expectedRevenue),
        ].join(' · '),
      ),
      onTap: () => OpportunityDetailRoute(id: o.id).push<void>(context),
    );
  }
}

class _AssignmentBanner extends ConsumerWidget {
  const _AssignmentBanner({required this.items});
  final List<Opportunity> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.assignment_ind_outlined),
        title: Text(l.newAssignmentBanner(items.length)),
        subtitle: Text(items.map((o) => o.title).join(', ')),
        trailing: TextButton(
          onPressed: () =>
              ref.read(assignmentWatcherProvider.notifier).dismiss(),
          child: Text(l.dismiss),
        ),
        onTap: () =>
            OpportunityDetailRoute(id: items.first.id).push<void>(context),
      ),
    );
  }
}
