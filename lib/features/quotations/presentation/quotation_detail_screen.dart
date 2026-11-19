import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/quotations/application/quotation_controllers.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:field_crm/features/quotations/presentation/quotation_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 2 → "2", 2.5 → "2.5".
String qty(double q) => q == q.roundToDouble() ? '${q.toInt()}' : '$q';

/// Items, total, status; confirm creates the invoice shown below.
class QuotationDetailScreen extends ConsumerStatefulWidget {
  const QuotationDetailScreen({required this.id, super.key});
  final String id;

  @override
  ConsumerState<QuotationDetailScreen> createState() =>
      _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends ConsumerState<QuotationDetailScreen> {
  bool _busy = false;

  Future<void> _confirm(Quotation q) async {
    final l = context.l10n;
    final f = ref.read(formattersProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmQuotation),
        content: Text(l.confirmQuotationBody(f.money(q.total))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('quotation_confirm_ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirmQuotation),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final r = await ref.read(quotationSaverProvider.notifier).confirm(q.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok(:final value) => l.quotationConfirmedMsg(value.number),
          Err(:final error) => failureMessage(context, error),
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);
    final q = ref.watch(quotationDetailProvider(widget.id));
    final invoice = ref.watch(quotationInvoiceProvider(widget.id)).valueOrNull;
    final customers = ref.watch(customerNamesProvider).valueOrNull ?? const {};
    final canConfirm = ref.watch(permissionsProvider).canCreateOpportunity;
    return Scaffold(
      appBar: AppBar(title: Text(q.value?.number ?? l.quotation)),
      body: AsyncView<Quotation>(
        value: q,
        onRetry: () => ref.invalidate(quotationDetailProvider(widget.id)),
        data: (q) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.number, style: theme.textTheme.headlineSmall),
                      InkWell(
                        onTap: () =>
                            CustomerDetailRoute(id: q.customerId)
                                .push<void>(context),
                        child: Text(
                          customers[q.customerId] ?? q.customerId,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        f.date(q.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                QuotationStatusPill(status: q.status),
              ],
            ),
            SectionHeader(l.lineItems),
            Panel(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final i in q.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  i.description,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                Text(
                                  '${qty(i.quantity)} × '
                                  '${f.money(i.unitPrice)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            f.money(i.total),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Text(l.total, style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        f.money(q.total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (q.notes != null) ...[
              SectionHeader(l.notes),
              Panel(padding: const EdgeInsets.all(16), child: Text(q.notes!)),
            ],
            if (invoice != null) ...[
              SectionHeader(l.invoice),
              Panel(child: InvoiceTile(invoice: invoice)),
            ],
            const SizedBox(height: 24),
            if (q.status == QuotationStatus.draft && canConfirm)
              FilledButton.icon(
                key: const Key('quotation_confirm'),
                onPressed: _busy ? null : () => _confirm(q),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(l.confirmQuotation),
              ),
          ],
        ),
      ),
    );
  }
}
