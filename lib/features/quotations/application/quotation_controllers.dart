import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quotation_controllers.g.dart';

@Riverpod(keepAlive: true)
Future<List<Quotation>> quotationList(
  Ref ref, {
  String? customerId,
  String? opportunityId,
}) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref
      .watch(quotationRepositoryProvider)
      .list(customerId: customerId, opportunityId: opportunityId)
      .orThrow;
}

@Riverpod(keepAlive: true)
Future<List<Product>> productList(Ref ref) {
  ref.watch(currentUserProvider);
  return ref.watch(quotationRepositoryProvider).products().orThrow;
}

@Riverpod(keepAlive: true)
Future<Quotation> quotationDetail(Ref ref, String id) {
  ref.watch(refreshTickProvider);
  return ref.watch(quotationRepositoryProvider).getById(id).orThrow;
}

@Riverpod(keepAlive: true)
Future<List<Invoice>> invoiceList(
  Ref ref, {
  String? customerId,
  bool pendingOnly = false,
}) {
  ref
    ..watch(refreshTickProvider)
    ..watch(currentUserProvider);
  return ref
      .watch(quotationRepositoryProvider)
      .invoices(customerId: customerId, pendingOnly: pendingOnly)
      .orThrow;
}

/// Invoice created by a quotation; `null` while it is still a draft.
@Riverpod(keepAlive: true)
Future<Invoice?> quotationInvoice(Ref ref, String quotationId) async {
  ref.watch(refreshTickProvider);
  final r = await ref
      .watch(quotationRepositoryProvider)
      .invoiceFor(quotationId);
  return r.valueOrNull;
}

// ponytail: quotations are online-only. Add WriteOperation values and replay
// support when drafting quotations offline matters.
@Riverpod(keepAlive: true)
class QuotationSaver extends _$QuotationSaver {
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
