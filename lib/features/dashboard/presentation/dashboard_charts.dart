import 'package:field_crm/app/providers.dart';
import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/clock.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/activities/application/activity_controllers.dart';
import 'package:field_crm/features/activities/domain/activity.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/opportunities/application/opportunity_controllers.dart';
import 'package:field_crm/features/pipeline/application/pipeline_controllers.dart';
import 'package:field_crm/features/pipeline/domain/pipeline_stage.dart';
import 'package:field_crm/features/quotations/application/quotation_controllers.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stage colours: one hue, light to dark in stage order; won = tertiary.
Color stageColor(ColorScheme scheme, int index, int count, {bool won = false}) {
  if (won) return scheme.tertiary;
  final t = count <= 1 ? 1.0 : 0.35 + 0.65 * index / (count - 1);
  return scheme.primary.withValues(alpha: t);
}

/// Open value split by stage as one stacked bar, with a legend. Tap → kanban.
class PipelineCard extends ConsumerWidget {
  const PipelineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stages = ref.watch(stagesProvider).valueOrNull ?? const <PipelineStage>[];
    final opps = ref.watch(opportunityListProvider()).valueOrNull;
    if (opps == null || stages.isEmpty) {
      return const Panel(child: LinearProgressIndicator());
    }
    final ordered = [...stages]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final byStage = {
      for (final s in ordered)
        s.id: opps.where((o) => o.stageId == s.id).toList(),
    };
    double value(String id) =>
        byStage[id]!.fold(0, (sum, o) => sum + o.expectedRevenue);
    final open = ordered.where((s) => !s.isWon);
    final openCount = open.fold(0, (n, s) => n + byStage[s.id]!.length);
    final openValue = open.fold<double>(0, (n, s) => n + value(s.id));
    final total = ordered.fold<double>(0, (n, s) => n + value(s.id));
    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: const Key('dashboard_pipeline'),
        onTap: () => const PipelineRoute().push<void>(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.money(openValue),
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          '${l.openPipeline} · ${l.openCount(openCount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 14),
              if (total > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      spacing: 2, // surface gap between segments
                      children: [
                        for (var i = 0; i < ordered.length; i++)
                          if (value(ordered[i].id) > 0)
                            Expanded(
                              flex: (value(ordered[i].id) / total * 1000)
                                  .round()
                                  .clamp(1, 1000),
                              child: ColoredBox(
                                color: stageColor(
                                  scheme,
                                  i,
                                  ordered.length,
                                  won: ordered[i].isWon,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              for (var i = 0; i < ordered.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: stageColor(
                            scheme,
                            i,
                            ordered.length,
                            won: ordered[i].isWon,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ordered[i].name,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${byStage[ordered[i].id]!.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 96,
                        child: Text(
                          f.money(value(ordered[i].id)),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Activities per day for the last seven days: one series, thin bars.
class WeekActivityCard extends ConsumerWidget {
  const WeekActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final zone = ref.watch(currentUserProvider)?.timezone ?? 'UTC';
    final now = ref.watch(clockProvider).now();
    final today = startOfDay(now, zone);
    final from = today.subtract(const Duration(days: 6));
    final acts = ref
        .watch(activityListProvider(ActivityFilter(dueFrom: from)))
        .value;
    if (acts == null) return const Panel(child: LinearProgressIndicator());
    final counts = List<int>.filled(7, 0);
    for (final a in acts) {
      final at = a.dueAt ?? a.updatedAt;
      final day = startOfDay(at, zone).difference(from).inDays;
      if (day >= 0 && day < 7) counts[day]++;
    }
    final max = counts.fold(0, (m, c) => c > m ? c : m);
    final total = counts.fold(0, (s, c) => s + c);
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.activitiesCount(total), style: theme.textTheme.headlineSmall),
          Text(
            l.last7Days,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (counts[i] > 0 && counts[i] == max)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${counts[i]}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        Semantics(
                          label:
                              '${f.date(from.add(Duration(days: i)))}: '
                              '${counts[i]}',
                          child: Container(
                            height: max == 0 ? 2 : 2 + 64 * counts[i] / max,
                            decoration: BoxDecoration(
                              color: counts[i] == 0
                                  ? scheme.surfaceContainerHighest
                                  : (i == 6
                                        ? scheme.primary
                                        : scheme.primary.withValues(
                                            alpha: 0.6,
                                          )),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    f.weekday(from.add(Duration(days: i)))[0],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: i == 6
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: i == 6 ? FontWeight.w700 : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pending invoices: amount due, count, overdue count. Tap → list.
class InvoicesCard extends ConsumerWidget {
  const InvoicesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = ref.watch(clockProvider).now();
    final items =
        ref.watch(invoiceListProvider(pendingOnly: true)).valueOrNull ??
        const <Invoice>[];
    final due = items.fold<double>(0, (s, i) => s + i.amount);
    final overdue = items.where((i) => i.dueAt.isBefore(now)).length;
    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: const Key('dashboard_invoices'),
        onTap: () => const PendingInvoicesRoute().push<void>(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              LeadingGlyph(
                icon: Icons.receipt_long_outlined,
                color: overdue > 0 ? scheme.error : scheme.tertiary,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.money(due), style: theme.textTheme.titleLarge),
                    Text(
                      [
                        l.amountDue,
                        '${items.length} ${l.pendingInvoices.toLowerCase()}',
                        if (overdue > 0) l.overdueCount(overdue),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overdue > 0
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
