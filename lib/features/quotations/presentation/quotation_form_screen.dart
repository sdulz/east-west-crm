import 'package:field_crm/core/format/app_formatters.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/save_feedback.dart';
import 'package:field_crm/core/widgets/search_picker.dart';
import 'package:field_crm/core/widgets/section.dart';
import 'package:field_crm/features/customers/application/customer_controllers.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/quotations/application/quotation_controllers.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// New quotation: customer (fixed when opened from a record), items, notes.
class QuotationFormScreen extends ConsumerStatefulWidget {
  const QuotationFormScreen({super.key, this.customerId, this.opportunityId});
  final String? customerId;
  final String? opportunityId;

  @override
  ConsumerState<QuotationFormScreen> createState() =>
      _QuotationFormScreenState();
}

class _LineControllers {
  Product? product;
  final quantity = TextEditingController(text: '1');
  final unitPrice = TextEditingController();

  /// Picking a product pre-fills the price; it stays editable.
  void pick(Product? p) {
    product = p;
    if (p != null) unitPrice.text = p.unitPrice.toStringAsFixed(0);
  }

  QuotationItem toItem() => QuotationItem(
    description: product?.name ?? '',
    productId: product?.id,
    quantity: double.tryParse(quantity.text) ?? 0,
    unitPrice: double.tryParse(unitPrice.text) ?? 0,
  );

  void dispose() {
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  final _form = GlobalKey<FormState>();
  final _lines = [_LineControllers()];
  final _notes = TextEditingController();
  late String? _customerId = widget.customerId;
  late final String _id = uuidV4();
  String? _itemsError;
  bool _saving = false;

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _notes.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0, (s, l) => s + l.toItem().total);

  Future<void> _save() async {
    setState(() => _itemsError = null);
    if (!_form.currentState!.validate() || _customerId == null) return;
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final r = await ref
        .read(quotationSaverProvider.notifier)
        .create(
          Quotation(
            id: _id,
            number: '',
            customerId: _customerId!,
            opportunityId: widget.opportunityId,
            ownerId: '',
            items: _lines.map((l) => l.toItem()).toList(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final l = context.l10n;
    switch (r) {
      case Ok():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saved)));
        Navigator.pop(context);
      case Err(error: ValidationFailure(field: 'items', :final message)):
        setState(() => _itemsError = message);
      case Err(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(context, error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(formattersProvider);
    final theme = Theme.of(context);
    final customers = ref.watch(customerListProvider()).valueOrNull ?? const [];
    final products = ref.watch(productListProvider).valueOrNull ?? const <Product>[];
    return Scaffold(
      appBar: AppBar(title: Text(l.newQuotation)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SearchPickerField<Customer>(
              key: const Key('quotation_customer'),
              label: l.customer,
              items: customers,
              labelOf: (c) => c.name,
              subtitleOf: (c) =>
                  [c.city, c.phone].whereType<String>().join(' · '),
              value: customers.where((c) => c.id == _customerId).firstOrNull,
              enabled: widget.customerId == null,
              onChanged: (c) => setState(() => _customerId = c.id),
              validator: (v) =>
                  v == null && _customerId == null ? l.selectCustomer : null,
            ),
            SectionHeader(
              l.lineItems,
              trailing: TextButton.icon(
                key: const Key('quotation_add_item'),
                onPressed: () => setState(() => _lines.add(_LineControllers())),
                icon: const Icon(Icons.add),
                label: Text(l.addItem),
              ),
            ),
            for (var i = 0; i < _lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SearchPickerField<Product>(
                              key: Key('item_product_$i'),
                              label: l.product,
                              items: products,
                              labelOf: (p) => p.name,
                              subtitleOf: (p) =>
                                  '${f.money(p.unitPrice)} / ${p.unit}',
                              value: _lines[i].product,
                              onChanged: (p) =>
                                  setState(() => _lines[i].pick(p)),
                              validator: (v) =>
                                  v == null ? l.selectProduct : null,
                            ),
                          ),
                          if (_lines.length > 1)
                            IconButton(
                              tooltip: l.removeItem,
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _lines.removeAt(i).dispose();
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: Key('item_quantity_$i'),
                              controller: _lines[i].quantity,
                              decoration: InputDecoration(
                                labelText: l.quantity,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') ?? 0) <= 0
                                  ? l.required
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              key: Key('item_price_$i'),
                              controller: _lines[i].unitPrice,
                              decoration: InputDecoration(
                                labelText: l.unitPrice,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => double.tryParse(v ?? '') == null
                                  ? l.required
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_itemsError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _itemsError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Text(l.total, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    f.money(_total),
                    key: const Key('quotation_total'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: l.notes),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SaveButton(
              key: const Key('quotation_save'),
              saving: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
