import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/activities/presentation/activity_tile.dart';
import 'package:field_crm/features/team/application/team_controller.dart';
import 'package:field_crm/features/team/domain/team.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-014. Routed only when `permissions.canViewTeam`; the repository
/// also refuses, so this screen renders the permission-denied state otherwise.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final overview = ref.watch(teamOverviewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.team)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(teamOverviewProvider.future),
        child: AsyncView<TeamOverview>(
          value: overview,
          onRetry: () => ref.invalidate(teamOverviewProvider),
          data: (t) => ListView(
            children: [
              ListTile(
                title: Text(t.team.name),
                subtitle: Text('${t.members.length} ${l.roleSalesperson}'),
              ),
              for (final m in t.members)
                ExpansionTile(
                  key: Key('team_member_${m.user.id}'),
                  leading: CircleAvatar(child: Text(m.user.name[0])),
                  title: Text(m.user.name),
                  subtitle: Text(
                    '${l.teamOpen(m.openOpportunities.length)} · '
                    '${l.teamOverdue(m.overdueActivities.length)}',
                  ),
                  children: [
                    for (final o in m.openOpportunities)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.work_outline),
                        title: Text(o.title),
                        subtitle: Text(f.money(o.expectedRevenue)),
                        onTap: () =>
                            OpportunityDetailRoute(id: o.id)
                                .push<void>(context),
                      ),
                    for (final a in m.overdueActivities)
                      ActivityTile(activity: a, showActions: false),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
