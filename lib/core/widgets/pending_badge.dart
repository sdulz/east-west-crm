import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/pending/application/pending_queue_controller.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows Pending / Failed for a record id, nothing otherwise (FR-MOB-013).
class PendingBadge extends ConsumerWidget {
  const PendingBadge({required this.targetId, super.key});
  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      pendingByTargetProvider.select((m) => m[targetId]),
    );
    if (status == null) return const SizedBox.shrink();
    final l = context.l10n;
    final failed = status == PendingStatus.failed;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: failed ? l.failed : l.pending,
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(
          failed ? Icons.error_outline : Icons.schedule,
          size: 16,
          color: failed ? scheme.onErrorContainer : scheme.onTertiaryContainer,
        ),
        label: Text(failed ? l.failed : l.pending),
        backgroundColor: failed
            ? scheme.errorContainer
            : scheme.tertiaryContainer,
        labelStyle: TextStyle(
          color: failed ? scheme.onErrorContainer : scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
