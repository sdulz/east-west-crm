import 'package:field_crm/app/router.dart';
import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/widgets/async_view.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/quotations/application/quotation_controllers.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuotationStatusPill extends StatelessWidget {
  const QuotationStatusPill({required this.status, super.key});
  final QuotationStatus status;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      QuotationStatus.draft => StatusPill(text: l.quotationDraft),
      QuotationStatus.confirmed => StatusPill(
        text: l.quotationConfirmed,
        color: scheme.primary,
      ),
    };
  }
}

/// Rows for a customer's or opportunity's quotations (inside a Panel).
class QuotationList extends ConsumerWidget {
  const QuotationList({super.key, this.customerId, this.opportunityId});
  final String? customerId;
  final String? opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(formattersProvider);
    final provider = quotationListProvider(
      customerId: customerId,
      opportunityId: opportunityId,
    );
    return AsyncView<List<Quotation>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      isEmpty: (v) => v.isEmpty,
      loading: const LinearProgressIndicator(),
      data: (items) => Column(
        children: [
          for (final q in items)
            ListTile(
              key: Key('quotation_${q.id}'),
              leading: const LeadingGlyph(icon: Icons.request_quote_outlined),
              title: Text(q.number),
              subtitle: Text('${f.money(q.total)} · ${f.date(q.createdAt)}'),
              trailing: QuotationStatusPill(status: q.status),
              onTap: () => QuotationDetailRoute(id: q.id).push<void>(context),
            ),
        ],
      ),
    );
  }
}

/// One invoice row with "Mark as paid" while pending.
class InvoiceTile extends ConsumerStatefulWidget {
  const InvoiceTile({
    required this.invoice,
    super.key,
    this.showCustomer = false,
  });
  final Invoice invoice;
  final bool showCustomer;

  @override
  ConsumerState<InvoiceTile> createState() => _InvoiceTileState();
}

class _InvoiceTileState extends ConsumerState<InvoiceTile> {
  bool _busy = false;

  Future<void> _markPaid() async {
    setState(() => _busy = true);
    final r = await ref
        .read(quotationSaverProvider.notifier)
        .markPaid(widget.invoice.id);
    if (!mounted) return;
    setState(() => _busy = false);
    final l = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (r) {
          Ok() => l.invoiceMarkedPaid,
          Err(:final error) => failureMessage(context, error),
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final scheme = Theme.of(context).colorScheme;
    final i = widget.invoice;
    final pending = i.status == InvoiceStatus.pending;
    final overdue = pending && i.dueAt.isBefore(DateTime.now().toUtc());
    String? customer;
    if (widget.showCustomer) {
      customer = ref.watch(customerNamesProvider).value?[i.customerId];
    }
    return ListTile(
      key: Key('invoice_${i.id}'),
      leading: LeadingGlyph(
        icon: Icons.receipt_long_outlined,
        color: overdue ? scheme.error : (pending ? scheme.tertiary : null),
      ),
      title: Text(customer == null ? i.number : '$customer · ${i.number}'),
      subtitle: Text(
        '${f.money(i.amount)} · '
        '${pending ? l.dueOn(f.date(i.dueAt)) : l.invoicePaid}',
        style: overdue ? TextStyle(color: scheme.error) : null,
      ),
      trailing: pending
          ? (_busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    key: Key('invoice_paid_${i.id}'),
                    onPressed: _markPaid,
                    child: Text(l.markPaid),
                  ))
          : StatusPill(text: l.invoicePaid, color: scheme.primary),
      onTap: () => QuotationDetailRoute(id: i.quotationId).push<void>(context),
    );
  }
}

/// Invoices for one customer (inside a Panel).
class InvoiceList extends ConsumerWidget {
  const InvoiceList({required this.customerId, super.key});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = invoiceListProvider(customerId: customerId);
    return AsyncView<List<Invoice>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      isEmpty: (v) => v.isEmpty,
      loading: const LinearProgressIndicator(),
      data: (items) =>
          Column(children: [for (final i in items) InvoiceTile(invoice: i)]),
    );
  }
}

/// All pending invoices across customers (Profile → Pending invoices).
class PendingInvoicesScreen extends ConsumerWidget {
  const PendingInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final provider = invoiceListProvider(pendingOnly: true);
    return Scaffold(
      appBar: AppBar(title: Text(l.pendingInvoices)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: AsyncView<List<Invoice>>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          isEmpty: (v) => v.isEmpty,
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            children: [
              for (final i in items)
                InvoiceTile(invoice: i, showCustomer: true),
            ],
          ),
        ),
      ),
    );
  }
}
