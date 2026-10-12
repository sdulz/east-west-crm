import 'dart:async';

import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/application/reminder_sync.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/presentation/activity_tile.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-007 Tasks tab: follow-ups grouped by due state.
class FollowUpsScreen extends ConsumerWidget {
  const FollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final followUps = ref.watch(myFollowUpsProvider);
    final zone = ref.watch(currentUserProvider)?.timezone ?? 'UTC';
    ref.listen(myFollowUpsProvider, (_, next) {
      final list = next.value;
      if (list != null) {
        unawaited(
          ref
              .read(reminderSyncProvider.notifier)
              .sync(list, title: l.reminderTitle, body: l.reminderBody),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(l.followUps),
        actions: [
          IconButton(
            key: const Key('followup_add'),
            tooltip: l.newFollowUp,
            icon: const Icon(Icons.alarm_add_outlined),
            onPressed: () =>
                ActivityFormRoute(type: ActivityType.todo.name)
                    .push<void>(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myFollowUpsProvider.future),
        child: AsyncView<List<Activity>>(
          value: followUps,
          onRetry: () => ref.invalidate(myFollowUpsProvider),
          isEmpty: (v) => v.isEmpty,
          data: (items) {
            final now = DateTime.now().toUtc();
            final dayEnd = startOfDay(now, zone).add(const Duration(days: 1));
            final overdue = items.where(
              (a) => a.state == ActivityState.overdue,
            );
            final open = items.where((a) => a.state == ActivityState.planned);
            final today = open.where((a) => a.dueAt!.isBefore(dayEnd));
            final upcoming = open.where((a) => !a.dueAt!.isBefore(dayEnd));
            final done = items.where((a) => a.state == ActivityState.done);
            return ListView(
              children: [
                _Section(l.overdue, overdue, key: const Key('section_overdue')),
                _Section(l.today, today, key: const Key('section_today')),
                _Section(
                  l.upcoming,
                  upcoming,
                  key: const Key('section_upcoming'),
                ),
                _Section(
                  l.done,
                  done,
                  collapsed: true,
                  key: const Key('section_done'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.items, {super.key, this.collapsed = false});
  final String title;
  final Iterable<Activity> items;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final list = items.toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      initiallyExpanded: !collapsed,
      title: Text('$title (${list.length})'),
      children: [for (final a in list) ActivityTile(activity: a)],
    );
  }
}
