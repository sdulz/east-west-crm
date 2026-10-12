import 'dart:async';

import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/activities/application/reminder_sync.dart';
import 'package:field_crm/features/activities/presentation/activity_tile.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/dashboard/application/dashboard_controller.dart';
import 'package:field_crm/features/dashboard/domain/dashboard_summary.dart';
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

    // FR-MOB-012: (re)schedule reminders on every refresh.
    ref.listen(dashboardControllerProvider, (_, next) {
      final s = next.value;
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
      final list = next.value;
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
        title: Text(l.navHome),
        actions: [
          IconButton(
            tooltip: l.search,
            icon: const Icon(Icons.search),
            onPressed: () => const SearchRoute().push<void>(context),
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
            padding: const EdgeInsets.all(16),
            children: [
              if (newlyAssigned.isNotEmpty)
                _AssignmentBanner(items: newlyAssigned),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _CountCard(
                    label: l.today,
                    count: s.today.length,
                    icon: Icons.today,
                    selected: _selected == _Group.today,
                    onTap: () => setState(() => _selected = _Group.today),
                  ),
                  _CountCard(
                    label: l.upcoming,
                    count: s.upcoming.length,
                    icon: Icons.upcoming,
                    selected: _selected == _Group.upcoming,
                    onTap: () => setState(() => _selected = _Group.upcoming),
                  ),
                  _CountCard(
                    label: l.overdue,
                    count: s.overdue.length,
                    icon: Icons.warning_amber,
                    selected: _selected == _Group.overdue,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => setState(() => _selected = _Group.overdue),
                  ),
                  _CountCard(
                    label: l.noFollowUp,
                    count: s.noFollowUp.length,
                    icon: Icons.help_outline,
                    selected: _selected == _Group.noFollowUp,
                    onTap: () => setState(() => _selected = _Group.noFollowUp),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(switch (_selected) {
                _Group.today => l.today,
                _Group.upcoming => l.upcoming,
                _Group.overdue => l.overdue,
                _Group.noFollowUp => l.noFollowUp,
              }, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._groupItems(s),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _groupItems(DashboardSummary s) {
    final l = context.l10n;
    if (_selected == _Group.noFollowUp) {
      if (s.noFollowUp.isEmpty) return [Text(l.emptyList)];
      return s.noFollowUp.map(_OpportunityRow.new).toList();
    }
    final items = switch (_selected) {
      _Group.today => s.today,
      _Group.upcoming => s.upcoming,
      _ => s.overdue,
    };
    if (items.isEmpty) return [Text(l.emptyList)];
    return items.map((a) => ActivityTile(activity: a)).toList();
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: context.l10n.dashboardCountCard(label, count),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                FittedBox(
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
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
    return ListTile(
      leading: const Icon(Icons.work_outline),
      title: Text(o.title),
      subtitle: Text(f.money(o.expectedRevenue)),
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
