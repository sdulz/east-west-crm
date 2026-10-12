import 'package:field_crm/app/env.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/l10n/generated/app_localizations.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/pending/application/pending_queue_controller.dart';
import 'package:field_crm/features/pending/domain/pending_write.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-013 pending centre: retry one, retry all, discard (confirmed).
class PendingCenterScreen extends ConsumerStatefulWidget {
  const PendingCenterScreen({super.key});

  @override
  ConsumerState<PendingCenterScreen> createState() =>
      _PendingCenterScreenState();
}

String? _errorText(AppLocalizations l, String? err) => switch (err) {
  null => null,
  'expired' => l.pendingExpired(AppEnv.pendingMaxAgeDays),
  _ => err,
};

class _PendingCenterScreenState extends ConsumerState<PendingCenterScreen> {
  final _busy = <String>{};
  bool _busyAll = false;

  Future<void> _retry(String id) async {
    setState(() => _busy.add(id));
    final ok = await ref
        .read(pendingQueueControllerProvider.notifier)
        .retry(id);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? context.l10n.saved : context.l10n.failed)),
    );
  }

  Future<void> _retryAll() async {
    setState(() => _busyAll = true);
    final n = await ref
        .read(pendingQueueControllerProvider.notifier)
        .retryAll();
    if (!mounted) return;
    setState(() => _busyAll = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${context.l10n.saved}: $n')));
  }

  Future<void> _discard(PendingWrite w) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.discardConfirmTitle),
        content: Text(l.discardConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('discard_confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.discard),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(pendingQueueControllerProvider.notifier).discard(w.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final queue = ref.watch(pendingQueueControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pendingCenter),
        actions: [
          TextButton.icon(
            key: const Key('retry_all'),
            onPressed: _busyAll || (queue.value?.isEmpty ?? true)
                ? null
                : _retryAll,
            icon: const Icon(Icons.refresh),
            label: Text(l.retryAll),
          ),
        ],
      ),
      body: AsyncView<List<PendingWrite>>(
        value: queue,
        onRetry: () => ref.invalidate(pendingQueueControllerProvider),
        isEmpty: (v) => v.isEmpty,
        emptyMessage: l.pendingEmpty,
        data: (items) => ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final w = items[i];
            final failed = w.status == PendingStatus.failed;
            final scheme = Theme.of(context).colorScheme;
            return ListTile(
              key: Key('pending_${w.id}'),
              leading: Icon(
                failed ? Icons.error_outline : Icons.schedule,
                color: failed ? scheme.error : null,
              ),
              title: Text(w.label.isEmpty ? w.operation.name : w.label),
              subtitle: Text(
                [
                  if (failed) l.failed else l.pending,
                  f.dateTime(w.createdAt),
                  l.pendingAttempts(w.attempts),
                  ?_errorText(l, w.lastError),
                ].join(' · '),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Key('retry_${w.id}'),
                    tooltip: l.retry,
                    icon: _busy.contains(w.id)
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: _busy.contains(w.id) ? null : () => _retry(w.id),
                  ),
                  IconButton(
                    key: Key('discard_${w.id}'),
                    tooltip: l.discard,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _discard(w),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
