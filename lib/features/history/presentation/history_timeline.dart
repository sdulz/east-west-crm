import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/history/application/history_controller.dart';
import 'package:field_crm/features/history/domain/history_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-010 chronological timeline (newest first).
class HistoryTimeline extends ConsumerWidget {
  const HistoryTimeline({required this.type, required this.id, super.key});
  final RelatedType type;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final entries = ref.watch(historyProvider(type, id));
    return AsyncView<List<HistoryEntry>>(
      value: entries,
      onRetry: () => ref.invalidate(historyProvider(type, id)),
      isEmpty: (v) => v.isEmpty,
      loading: const LinearProgressIndicator(),
      data: (items) => Column(
        children: [
          for (final e in items)
            ListTile(
              key: Key('history_${e.id}'),
              leading: Icon(switch (e.kind) {
                HistoryKind.activity => Icons.event_available_outlined,
                HistoryKind.note => Icons.sticky_note_2_outlined,
                HistoryKind.stageChange => Icons.swap_vert,
                HistoryKind.ownerChange => Icons.swap_horiz,
              }),
              title: Text(switch (e.kind) {
                HistoryKind.stageChange => l.historyStageChange(
                  e.from ?? '',
                  e.to ?? '',
                ),
                HistoryKind.ownerChange => l.historyOwnerChange(
                  e.from ?? '',
                  e.to ?? '',
                ),
                _ => e.text ?? '',
              }),
              subtitle: Text('${e.actorName} · ${f.dateTime(e.at)}'),
            ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.type, required this.id, super.key});
  final RelatedType type;
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.history)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [HistoryTimeline(type: type, id: id)],
    ),
  );
}
