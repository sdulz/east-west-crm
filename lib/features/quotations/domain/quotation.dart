import 'package:freezed_annotation/freezed_annotation.dart';

part 'quotation.freezed.dart';
part 'quotation.g.dart';

enum QuotationStatus { draft, confirmed }

enum InvoiceStatus { pending, paid }

/// Catalogue entry a quotation line is picked from.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double unitPrice,
    @Default('unit') String unit,
    @Default(true) bool isActive,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

@freezed
abstract class QuotationItem with _$QuotationItem {
  const factory QuotationItem({
    required String description,
    String? productId,
    @Default(1) double quantity,
    @Default(0) double unitPrice,
  }) = _QuotationItem;
  const QuotationItem._();

  factory QuotationItem.fromJson(Map<String, dynamic> json) =>
      _$QuotationItemFromJson(json);

  double get total => quantity * unitPrice;
}

/// A priced offer for a customer, optionally tied to an opportunity.
/// Confirming it creates an [Invoice].
@freezed
abstract class Quotation with _$Quotation {
  const factory Quotation({
    required String id,
    required String number,
    required String customerId,
    required String ownerId,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? opportunityId,
    String? notes,
    @Default(<QuotationItem>[]) List<QuotationItem> items,
    @Default(QuotationStatus.draft) QuotationStatus status,
  }) = _Quotation;
  const Quotation._();

  factory Quotation.fromJson(Map<String, dynamic> json) =>
      _$QuotationFromJson(json);

  double get total => items.fold(0, (s, i) => s + i.total);
}

@freezed
abstract class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String number,
    required String quotationId,
    required String customerId,
    required double amount,
    required DateTime dueAt,
    required DateTime createdAt,
    @Default(InvoiceStatus.pending) InvoiceStatus status,
    DateTime? paidAt,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}
