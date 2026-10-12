import 'dart:async';

import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/pending_badge.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pipeline/application/pipeline_controllers.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-008 kanban. A dragged card shows in the target column only while
/// the repository call is in flight; a rejection snaps it back with the reason.
class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen> {
  /// opportunityId -> target stage while a move awaits confirmation.
  final _inFlight = <String, String>{};
  final _expandedFolded = <String>{};

  Future<void> _move(Opportunity o, PipelineStage to) async {
    setState(() => _inFlight[o.id] = to.id);
    final out = await ref
        .read(opportunitySaverProvider.notifier)
        .changeStage(o, toStageId: to.id);
    if (!mounted) return;
    setState(() => _inFlight.remove(o.id));
    await showSaveOutcome(
      context,
      out,
      successMessage: context.l10n.stageMoved(to.name),
      onReloadLatest: () async => ref.invalidate(opportunityListProvider()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stages = ref.watch(stagesProvider);
    final opps = ref.watch(opportunityListProvider());
    final canMove = ref.watch(permissionsProvider).canChangeStage;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pipeline),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(opportunityListProvider()),
          ),
        ],
      ),
      body: AsyncView<List<PipelineStage>>(
        value: stages,
        onRetry: () => ref.invalidate(stagesProvider),
        data: (stageList) => AsyncView<List<Opportunity>>(
          value: opps,
          onRetry: () => ref.invalidate(opportunityListProvider()),
          data: (items) => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            itemCount: stageList.length,
            itemBuilder: (_, i) {
              final stage = stageList[i];
              final column = items
                  .where((o) => (_inFlight[o.id] ?? o.stageId) == stage.id)
                  .toList();
              final folded =
                  stage.isFolded && !_expandedFolded.contains(stage.id);
              return DragTarget<Opportunity>(
                onWillAcceptWithDetails: (d) =>
                    canMove && d.data.stageId != stage.id,
                onAcceptWithDetails: (d) {
                  final from = stageList.firstWhere(
                    (s) => s.id == d.data.stageId,
                  );
                  if (!from.canMoveTo(stage.id)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.stageNotAllowed(from.name, stage.name)),
                      ),
                    );
                    return;
                  }
                  unawaited(_move(d.data, stage));
                },
                builder: (context, candidates, _) => _Column(
                  stage: stage,
                  items: column,
                  folded: folded,
                  highlighted: candidates.isNotEmpty,
                  inFlight: _inFlight,
                  canMove: canMove,
                  onToggleFold: () => setState(() {
                    if (!_expandedFolded.remove(stage.id)) {
                      _expandedFolded.add(stage.id);
                    }
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Column extends ConsumerWidget {
  const _Column({
    required this.stage,
    required this.items,
    required this.folded,
    required this.highlighted,
    required this.inFlight,
    required this.canMove,
    required this.onToggleFold,
  });
  final PipelineStage stage;
  final List<Opportunity> items;
  final bool folded;
  final bool highlighted;
  final Map<String, String> inFlight;
  final bool canMove;
  final VoidCallback onToggleFold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final f = ref.watch(formattersProvider);
    final total = items.fold<double>(0, (s, o) => s + o.expectedRevenue);
    final header = InkWell(
      onTap: stage.isFolded ? onToggleFold : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: folded
            ? RotatedBox(
                quarterTurns: 3,
                child: Text('${stage.name} (${items.length})'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(context.l10n.openCount(items.length)),
                    ],
                  ),
                  Text(
                    f.money(total),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
    return Container(
      key: Key('column_${stage.id}'),
      width: folded ? 56 : 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: stage.isWon ? Border.all(color: scheme.tertiary) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (!folded)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final o = items[i];
                  final moving = inFlight.containsKey(o.id);
                  final card = _Card(o: o, moving: moving);
                  if (!canMove || moving) return card;
                  return LongPressDraggable<Opportunity>(
                    data: o,
                    feedback: SizedBox(
                      width: 260,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: card,
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: card),
                    child: card,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.o, required this.moving});
  final Opportunity o;
  final bool moving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(formattersProvider);
    return Card(
      key: Key('card_${o.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(o.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${f.money(o.expectedRevenue)} · ${o.probability}%'),
        trailing: moving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PendingBadge(targetId: o.id),
        onTap: () => OpportunityDetailRoute(id: o.id).push<void>(context),
      ),
    );
  }
}
