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
    final fg = failed ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    return Semantics(
      label: failed ? l.failed : l.pending,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: failed ? scheme.errorContainer : scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed ? Icons.error_outline : Icons.schedule,
              size: 14,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(
              failed ? l.failed : l.pending,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
