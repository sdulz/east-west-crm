import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';

abstract interface class QuotationRepository {
  Future<Result<List<Product>, Failure>> products();
  Future<Result<List<Quotation>, Failure>> list({
    String? customerId,
    String? opportunityId,
  });
  Future<Result<Quotation, Failure>> getById(String id);

  /// `quotation.id` is a client-generated UUID so retries are idempotent.
  /// The repository assigns the number.
  Future<Result<Quotation, Failure>> create(Quotation quotation);

  /// Confirms a draft and returns the invoice it created.
  Future<Result<Invoice, Failure>> confirm(String quotationId);

  Future<Result<List<Invoice>, Failure>> invoices({
    String? customerId,
    bool pendingOnly = false,
  });
  Future<Result<Invoice, Failure>> invoiceFor(String quotationId);
  Future<Result<Invoice, Failure>> markPaid(String invoiceId);
}
