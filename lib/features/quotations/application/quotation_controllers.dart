import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';

class QuotationListParams {
  final String? customerId;
  final String? opportunityId;
  const QuotationListParams({this.customerId, this.opportunityId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotationListParams &&
          customerId == other.customerId &&
          opportunityId == other.opportunityId;

  @override
  int get hashCode => Object.hash(customerId, opportunityId);
}

final _quotationListFamily =
    FutureProvider.family<List<Quotation>, QuotationListParams>((ref, params) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref
      .watch(quotationRepositoryProvider)
      .list(customerId: params.customerId, opportunityId: params.opportunityId)
      .orThrow;
});

FutureProvider<List<Quotation>> quotationListProvider({
  String? customerId,
  String? opportunityId,
}) =>
    _quotationListFamily(QuotationListParams(
      customerId: customerId,
      opportunityId: opportunityId,
    ));

final productListProvider = FutureProvider<List<Product>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(quotationRepositoryProvider).products().orThrow;
});

final quotationDetailProvider =
    FutureProvider.family<Quotation, String>((ref, id) {
  ref.watch(refreshTickProvider);
  return ref.watch(quotationRepositoryProvider).getById(id).orThrow;
});

class InvoiceListParams {
  final String? customerId;
  final bool pendingOnly;
  const InvoiceListParams({this.customerId, this.pendingOnly = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceListParams &&
          customerId == other.customerId &&
          pendingOnly == other.pendingOnly;

  @override
  int get hashCode => Object.hash(customerId, pendingOnly);
}

final _invoiceListFamily =
    FutureProvider.family<List<Invoice>, InvoiceListParams>((ref, params) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref
      .watch(quotationRepositoryProvider)
      .invoices(
        customerId: params.customerId,
        pendingOnly: params.pendingOnly,
      )
      .orThrow;
});

FutureProvider<List<Invoice>> invoiceListProvider({
  String? customerId,
  bool pendingOnly = false,
}) =>
    _invoiceListFamily(InvoiceListParams(
      customerId: customerId,
      pendingOnly: pendingOnly,
    ));

final quotationInvoiceProvider =
    FutureProvider.family<Invoice?, String>((ref, quotationId) async {
  ref.watch(refreshTickProvider);
  final r = await ref
      .watch(quotationRepositoryProvider)
      .invoiceFor(quotationId);
  return r.valueOrNull;
});

class QuotationSaver extends Notifier<void> {
  @override
  void build() {}

  Future<Result<T, Failure>> _confirmed<T>(Future<Result<T, Failure>> f) async {
    final r = await f;
    if (r.isOk) ref.read(refreshTickProvider.notifier).bump();
    return r;
  }

  Future<Result<Quotation, Failure>> create(Quotation q) =>
      _confirmed(ref.read(quotationRepositoryProvider).create(q));

  Future<Result<Invoice, Failure>> confirm(String quotationId) =>
      _confirmed(ref.read(quotationRepositoryProvider).confirm(quotationId));

  Future<Result<Invoice, Failure>> markPaid(String invoiceId) =>
      _confirmed(ref.read(quotationRepositoryProvider).markPaid(invoiceId));
}

final quotationSaverProvider =
    NotifierProvider<QuotationSaver, void>(QuotationSaver.new);
