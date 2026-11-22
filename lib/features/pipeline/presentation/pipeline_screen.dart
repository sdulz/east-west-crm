import 'dart:async';

import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/pending_badge.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/handover/application/user_directory_controllers.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/pipeline/application/pipeline_controllers.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-MOB-008 kanban. A dragged card shows in the target column only while
/// the repository call is in flight; a rejection snaps it back with the reason.
/// Phones: one column fills the width with the next one peeking; tap the
/// stage chips to jump, or use a card's "move" button instead of dragging.
class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen> {
  /// opportunityId -> target stage while a move awaits confirmation.
  final _inFlight = <String, String>{};
  final _expandedFolded = <String>{};
  final _scroll = ScrollController();

  static const _gap = 12.0;
  static const _foldedWidth = 48.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _columnWidth(BuildContext context) =>
      (MediaQuery.sizeOf(context).width - 56).clamp(240.0, 320.0);

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

  bool _tryMove(Opportunity o, List<PipelineStage> stages, PipelineStage to) {
    final from = stages.firstWhere((s) => s.id == o.stageId);
    if (!from.canMoveTo(to.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.stageNotAllowed(from.name, to.name)),
        ),
      );
      return false;
    }
    unawaited(_move(o, to));
    return true;
  }

  Future<void> _pickStage(Opportunity o, List<PipelineStage> stages) async {
    final from = stages.firstWhere((s) => s.id == o.stageId);
    final to = await showModalBottomSheet<PipelineStage>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ctx.l10n.moveTo,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ),
            ),
            for (final s in stages)
              ListTile(
                key: Key('move_option_${s.id}'),
                enabled: s.id != from.id && from.canMoveTo(s.id),
                leading: Icon(
                  s.id == from.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(s.name),
                onTap: () => Navigator.pop(ctx, s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (to != null && mounted) _tryMove(o, stages, to);
  }

  void _jumpTo(int index, double width) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      (index * (width + _gap)).clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final stages = ref.watch(stagesProvider);
    final opps = ref.watch(opportunityListProvider());
    final canMove = ref.watch(permissionsProvider).canChangeStage;
    final width = _columnWidth(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pipeline),
        actions: [
          IconButton(
            key: const Key('open_list'),
            tooltip: l.listView,
            icon: const Icon(Icons.view_list_outlined),
            onPressed: () => const OpportunityListRoute().push<void>(context),
          ),
          if (ref.watch(permissionsProvider).canCreateOpportunity)
            IconButton(
              key: const Key('opportunity_add'),
              tooltip: l.newOpportunity,
              icon: const Icon(Icons.add_business_outlined),
              onPressed: () => const OpportunityNewRoute().push<void>(context),
            ),
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
          data: (items) {
            final open = items.where(
              (o) => !stageList.any((s) => s.id == o.stageId && s.isWon),
            );
            final openValue = open.fold<double>(
              0,
              (s, o) => s + o.expectedRevenue,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l.openValue(open.length, f.money(openValue)),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stageList.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final s = stageList[i];
                      final n = items.where((o) => o.stageId == s.id).length;
                      return ActionChip(
                        key: Key('stage_chip_${s.id}'),
                        label: Text('${s.name}  $n'),
                        onPressed: () => _jumpTo(i, width),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: stageList.length,
                    itemBuilder: (_, i) {
                      final stage = stageList[i];
                      final column = items
                          .where(
                            (o) => (_inFlight[o.id] ?? o.stageId) == stage.id,
                          )
                          .toList();
                      final folded =
                          stage.isFolded && !_expandedFolded.contains(stage.id);
                      return DragTarget<Opportunity>(
                        onWillAcceptWithDetails: (d) =>
                            canMove && d.data.stageId != stage.id,
                        onAcceptWithDetails: (d) =>
                            _tryMove(d.data, stageList, stage),
                        builder: (context, candidates, _) => _Column(
                          stage: stage,
                          items: column,
                          width: folded ? _foldedWidth : width,
                          folded: folded,
                          highlighted: candidates.isNotEmpty,
                          inFlight: _inFlight,
                          canMove: canMove,
                          onToggleFold: () => setState(() {
                            if (!_expandedFolded.remove(stage.id)) {
                              _expandedFolded.add(stage.id);
                            }
                          }),
                          onMove: (o) => _pickStage(o, stageList),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Column extends ConsumerWidget {
  const _Column({
    required this.stage,
    required this.items,
    required this.width,
    required this.folded,
    required this.highlighted,
    required this.inFlight,
    required this.canMove,
    required this.onToggleFold,
    required this.onMove,
  });
  final PipelineStage stage;
  final List<Opportunity> items;
  final double width;
  final bool folded;
  final bool highlighted;
  final Map<String, String> inFlight;
  final bool canMove;
  final VoidCallback onToggleFold;
  final ValueChanged<Opportunity> onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = ref.watch(formattersProvider);
    final total = items.fold<double>(0, (s, o) => s + o.expectedRevenue);
    final accent = stage.isWon ? scheme.tertiary : scheme.primary;
    final header = InkWell(
      onTap: stage.isFolded ? onToggleFold : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
        child: folded
            ? RotatedBox(
                quarterTurns: 3,
                child: Text(
                  '${stage.name} (${items.length})',
                  style: theme.textTheme.labelLarge,
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stage.name, style: theme.textTheme.titleMedium),
                        Text(
                          f.money(total),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${items.length}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  if (stage.isFolded)
                    IconButton(
                      icon: const Icon(Icons.unfold_less),
                      onPressed: onToggleFold,
                    ),
                ],
              ),
      ),
    );
    return AnimatedContainer(
      key: Key('column_${stage.id}'),
      duration: const Duration(milliseconds: 200),
      width: width,
      margin: const EdgeInsets.only(right: _PipelineScreenState._gap),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (!folded)
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.emptyList,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final o = items[i];
                        final moving = inFlight.containsKey(o.id);
                        final card = _Card(
                          o: o,
                          moving: moving,
                          onMove: canMove && !moving ? () => onMove(o) : null,
                        );
                        if (!canMove || moving) return card;
                        return LongPressDraggable<Opportunity>(
                          data: o,
                          feedback: SizedBox(
                            width: width - 16,
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
  const _Card({required this.o, required this.moving, this.onMove});
  final Opportunity o;
  final bool moving;
  final VoidCallback? onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = ref.watch(formattersProvider);
    final customer =
        ref.watch(customerNamesProvider).valueOrNull?[o.customerId];
    final owner = ref.watch(userNamesProvider).valueOrNull?[o.ownerId];
    return Material(
      key: Key('card_${o.id}'),
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => OpportunityDetailRoute(id: o.id).push<void>(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        if (customer != null)
                          Text(
                            customer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (moving)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (onMove != null)
                    IconButton(
                      key: Key('move_${o.id}'),
                      tooltip: context.l10n.moveTo,
                      icon: const Icon(Icons.drive_file_move_outline),
                      onPressed: onMove,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    f.money(o.expectedRevenue),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${o.probability}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: o.probability / 100,
                    minHeight: 3,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  LeadingGlyph(
                    text: (owner ?? '?')[0],
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      owner ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PendingBadge(targetId: o.id),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
