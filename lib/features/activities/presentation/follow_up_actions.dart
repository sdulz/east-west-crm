import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/application/reminder_sync.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// FR-MOB-007: complete with outcome.
Future<void> completeFollowUp(
  BuildContext context,
  WidgetRef ref,
  Activity a,
) async {
  final l = context.l10n;
  final ctrl = TextEditingController();
  final outcome = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.completeWithOutcome),
      content: TextField(
        key: const Key('outcome_field'),
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: l.outcome),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          key: const Key('outcome_submit'),
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(l.complete),
        ),
      ],
    ),
  );
  if (outcome == null || !context.mounted) return;
  final out = await ref
      .read(activitySaverProvider.notifier)
      .complete(a, outcome: outcome);
  if (out is SaveSuccess) {
    await ref.read(reminderSyncProvider.notifier).cancelFor(a.id);
  }
  if (context.mounted) await showSaveOutcome(context, out);
}

/// FR-MOB-007: reschedule with date + time pickers in the user's timezone.
Future<void> rescheduleFollowUp(
  BuildContext context,
  WidgetRef ref,
  Activity a,
) async {
  final picked = await pickDateTime(context, ref, initial: a.dueAt);
  if (picked == null || !context.mounted) return;
  final out = await ref
      .read(activitySaverProvider.notifier)
      .reschedule(a, dueAt: picked);
  if (out is SaveSuccess) {
    await ref.read(reminderSyncProvider.notifier).cancelFor(a.id);
  }
  if (context.mounted) await showSaveOutcome(context, out);
}

/// Returns a UTC instant chosen as local wall-clock time in the user's zone.
Future<DateTime?> pickDateTime(
  BuildContext context,
  WidgetRef ref, {
  DateTime? initial,
}) async {
  final zone = ref.read(currentUserProvider)?.timezone ?? 'UTC';
  final nowLocal = inZone(DateTime.now().toUtc(), zone);
  final init = initial == null ? nowLocal : inZone(initial, zone);
  final date = await showDatePicker(
    context: context,
    initialDate: init,
    firstDate: nowLocal.subtract(const Duration(days: 365)),
    lastDate: nowLocal.add(const Duration(days: 365 * 2)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: init.hour, minute: init.minute),
  );
  if (time == null) return null;
  return tz.TZDateTime(
    init.location,
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  ).toUtc();
}
