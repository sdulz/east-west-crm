import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/mock/mock_validation.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:field_crm/features/quotations/domain/quotation_repository.dart';

class MockQuotationRepository implements QuotationRepository {
  MockQuotationRepository(this.store);
  final MockStore store;

  List<Quotation> get _all => store.state.quotations;
  List<Invoice> get _invoices => store.state.invoices;

  @override
  Future<Result<List<Product>, Failure>> products() => store.call(() {
    store.currentUser;
    return store.state.products.where((p) => p.isActive).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  });

  static String _number(String prefix, int n) =>
      '$prefix-${n.toString().padLeft(4, '0')}';

  @override
  Future<Result<List<Quotation>, Failure>> list({
    String? customerId,
    String? opportunityId,
  }) => store.call(() {
    store.currentUser;
    return _all
        .where((q) => customerId == null || q.customerId == customerId)
        .where((q) => opportunityId == null || q.opportunityId == opportunityId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  @override
  Future<Result<Quotation, Failure>> getById(String id) => store.call(() {
    store.currentUser;
    final q = _all.where((q) => q.id == id).firstOrNull;
    if (q == null) throw const MockFailure(Failure.unknown('Not found'));
    return q;
  });

  @override
  Future<Result<Quotation, Failure>> create(Quotation quotation) =>
      store.call(() {
        final me = store.currentUser;
        if (!me.permissions.canCreateOpportunity) {
          throw const MockFailure(Failure.permissionDenied());
        }
        final existing = _all.where((q) => q.id == quotation.id).firstOrNull;
        if (existing != null) return existing;
        if (quotation.items.isEmpty) {
          throw const MockFailure(
            Failure.validation('Add at least one item', field: 'items'),
          );
        }
        for (final i in quotation.items) {
          if (i.productId != null &&
              !store.state.products.any((p) => p.id == i.productId)) {
            throw const MockFailure(
              Failure.validation('Product does not exist', field: 'items'),
            );
          }
          MockValidation.required(i.description, 'items', 'Description');
          MockValidation.range(i.quantity, 0.001, 1e9, 'items', 'Quantity');
          MockValidation.range(i.unitPrice, 0, 1e12, 'items', 'Unit price');
        }
        if (!store.state.customers.any((c) => c.id == quotation.customerId)) {
          throw const MockFailure(
            Failure.validation('Customer does not exist', field: 'customerId'),
          );
        }
        final now = store.clock.now();
        final saved = quotation.copyWith(
          number: _number('Q', _all.length + 1),
          ownerId: me.id,
          status: QuotationStatus.draft,
          createdAt: now,
          updatedAt: now,
        );
        _all.add(saved);
        return saved;
      }, write: true);

  @override
  Future<Result<Invoice, Failure>> confirm(String quotationId) =>
      store.call(() {
        final me = store.currentUser;
        if (!me.permissions.canCreateOpportunity) {
          throw const MockFailure(Failure.permissionDenied());
        }
        final idx = _all.indexWhere((q) => q.id == quotationId);
        if (idx < 0) throw const MockFailure(Failure.unknown('Not found'));
        // Idempotent: confirming twice returns the same invoice.
        final existing = _invoices
            .where((i) => i.quotationId == quotationId)
            .firstOrNull;
        if (existing != null) return existing;
        final now = store.clock.now();
        final q = _all[idx].copyWith(
          status: QuotationStatus.confirmed,
          updatedAt: now,
        );
        _all[idx] = q;
        final invoice = Invoice(
          id: uuidV4(),
          number: _number('INV', _invoices.length + 1),
          quotationId: q.id,
          customerId: q.customerId,
          amount: q.total,
          dueAt: now.add(const Duration(days: 30)),
          createdAt: now,
        );
        _invoices.add(invoice);
        return invoice;
      }, write: true);

  @override
  Future<Result<List<Invoice>, Failure>> invoices({
    String? customerId,
    bool pendingOnly = false,
  }) => store.call(() {
    store.currentUser;
    return _invoices
        .where((i) => customerId == null || i.customerId == customerId)
        .where((i) => !pendingOnly || i.status == InvoiceStatus.pending)
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  });

  @override
  Future<Result<Invoice, Failure>> invoiceFor(String quotationId) =>
      store.call(() {
        store.currentUser;
        final i = _invoices
            .where((i) => i.quotationId == quotationId)
            .firstOrNull;
        if (i == null) throw const MockFailure(Failure.unknown('Not found'));
        return i;
      });

  @override
  Future<Result<Invoice, Failure>> markPaid(String invoiceId) => store.call(() {
    store.currentUser;
    final idx = _invoices.indexWhere((i) => i.id == invoiceId);
    if (idx < 0) throw const MockFailure(Failure.unknown('Not found'));
    final paid = _invoices[idx].copyWith(
      status: InvoiceStatus.paid,
      paidAt: store.clock.now(),
    );
    _invoices[idx] = paid;
    return paid;
  }, write: true);
}
