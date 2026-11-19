import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/pending_badge.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/activities/presentation/follow_up_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

IconData activityIcon(ActivityType t) => switch (t) {
  ActivityType.call => Icons.call_outlined,
  ActivityType.visit => Icons.directions_walk,
  ActivityType.meeting => Icons.groups_outlined,
  ActivityType.note => Icons.sticky_note_2_outlined,
  ActivityType.todo => Icons.check_circle_outline,
};

/// One activity / follow-up row with complete + reschedule actions.
class ActivityTile extends ConsumerWidget {
  const ActivityTile({
    required this.activity,
    super.key,
    this.showActions = true,
  });
  final Activity activity;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final scheme = Theme.of(context).colorScheme;
    final a = activity;
    final overdue = a.state == ActivityState.overdue;
    final done = a.state == ActivityState.done;
    final typeLabel =
        ref
            .watch(activityTypesProvider)
            .value
            ?.where((t) => t.type == a.type)
            .firstOrNull
            ?.label ??
        a.type.name;
    return ListTile(
      leading: Icon(
        activityIcon(a.type),
        color: overdue ? scheme.error : (done ? scheme.outline : null),
      ),
      title: Text(
        a.summary,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        [
          typeLabel,
          if (a.dueAt != null) f.dateTime(a.dueAt!),
          if (overdue) l.overdue,
          if (a.outcome != null) '${l.outcome}: ${a.outcome}',
        ].join(' · '),
        style: overdue ? TextStyle(color: scheme.error) : null,
      ),
      isThreeLine: a.outcome != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PendingBadge(targetId: a.id),
          if (showActions && !done && a.type != ActivityType.note)
            PopupMenuButton<String>(
              tooltip: l.details,
              onSelected: (v) => switch (v) {
                'complete' => completeFollowUp(context, ref, a),
                _ => rescheduleFollowUp(context, ref, a),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'complete', child: Text(l.complete)),
                PopupMenuItem(value: 'reschedule', child: Text(l.reschedule)),
              ],
            ),
        ],
      ),
    );
  }
}
