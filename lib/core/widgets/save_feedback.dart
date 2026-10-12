import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/pending/application/write_coordinator.dart';
import 'package:flutter/material.dart';

/// FR-MOB-015: snackbars only after the repository answered.
/// Returns true when the caller should pop (saved or queued).
Future<bool> showSaveOutcome<T>(
  BuildContext context,
  SaveOutcome<T> outcome, {
  String? successMessage,
  Future<void> Function()? onReloadLatest,
}) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  switch (outcome) {
    case SaveSuccess():
      messenger.showSnackBar(
        SnackBar(content: Text(successMessage ?? l.saved)),
      );
      return true;
    case SaveQueued():
      messenger.showSnackBar(SnackBar(content: Text(l.queuedForRetry)));
      return true;
    case SaveRejected(:final failure):
      if (failure is ConflictFailure) {
        final reload = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.conflictTitle),
            content: Text(l.conflictBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.keepEditing),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.reloadLatest),
              ),
            ],
          ),
        );
        if ((reload ?? false) && onReloadLatest != null) await onReloadLatest();
        return false;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(context, failure))),
      );
      return false;
  }
}

/// Inline progress button (FR-MOB-015).
class SaveButton extends StatelessWidget {
  const SaveButton({
    required this.saving,
    required this.onPressed,
    super.key,
    this.label,
  });
  final bool saving;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FilledButton.icon(
      onPressed: saving ? null : onPressed,
      icon: saving
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(saving ? l.saving : (label ?? l.save)),
    );
  }
}
