import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/quotations/domain/quotation.dart';
import 'package:field_crm/features/quotations/domain/quotation_repository.dart';

class ApiQuotationRepository implements QuotationRepository {
  ApiQuotationRepository(this.client);

  final CrmApiClient client;

  static const Map<String, String> _quotationFieldMap = {
    'customer_id': 'customerId',
    'opportunity_id': 'opportunityId',
    'notes': 'notes',
    'items': 'items',
    'product_id': 'items',
    'quantity': 'items',
    'unit_price': 'items',
    'description': 'items',
  };

  @override
  Future<Result<List<Product>, Failure>> products() {
    return client.get<List<Product>>(
      ApiConstant.productsUrl,
      params: const {'page': 1, 'limit': 100},
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map) _parseProduct(Map<String, dynamic>.from(item)),
        ]
          ..removeWhere((p) => !p.isActive)
          ..sort((a, b) => a.name.compareTo(b.name));
      },
    );
  }

  @override
  Future<Result<List<Quotation>, Failure>> list({
    String? customerId,
    String? opportunityId,
  }) {
    final customerIdInt = customerId != null ? int.tryParse(customerId) : null;
    final oppIdInt = opportunityId != null ? int.tryParse(opportunityId) : null;
    return client.get<List<Quotation>>(
      ApiConstant.quotationsUrl,
      params: {
        'page': 1,
        'limit': 100,
        if (customerIdInt != null && customerIdInt > 0)
          'customer_id': customerIdInt,
        if (oppIdInt != null && oppIdInt > 0) 'opportunity_id': oppIdInt,
      },
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map) _parseQuotation(Map<String, dynamic>.from(item)),
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      },
    );
  }

  @override
  Future<Result<Quotation, Failure>> getById(String id) {
    return client.get<Quotation>(
      ApiConstant.quotationByIdUrl(id),
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return _parseQuotation(data);
      },
    );
  }

  @override
  Future<Result<Quotation, Failure>> create(Quotation quotation) async {
    if (quotation.items.isEmpty) {
      return const Err(
        Failure.validation('Add at least one item', field: 'items'),
      );
    }
    final customerIdInt = int.tryParse(quotation.customerId);
    if (customerIdInt == null || customerIdInt <= 0) {
      return const Err(
        Failure.validation('Customer does not exist', field: 'customerId'),
      );
    }
    final oppIdInt = quotation.opportunityId != null
        ? int.tryParse(quotation.opportunityId!)
        : null;

    final itemsPayload = <Map<String, dynamic>>[];
    for (final item in quotation.items) {
      final prodId = item.productId != null
          ? int.tryParse(item.productId!)
          : null;
      if (prodId == null || prodId <= 0) {
        return const Err(
          Failure.validation('Product does not exist', field: 'items'),
        );
      }
      if (item.quantity <= 0) {
        return const Err(
          Failure.validation('Quantity must be greater than 0', field: 'items'),
        );
      }
      final desc = item.description.trim();
      itemsPayload.add({
        'product_id': prodId,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        if (desc.isNotEmpty) 'description': desc,
      });
    }

    final notes = quotation.notes?.trim();
    final body = <String, dynamic>{
      'customer_id': customerIdInt,
      if (oppIdInt != null && oppIdInt > 0) 'opportunity_id': oppIdInt,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': itemsPayload,
    };

    return client.post<Quotation>(
      ApiConstant.quotationsUrl,
      body: body,
      fieldMap: _quotationFieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return _parseQuotation(data);
      },
    );
  }

  @override
  Future<Result<Invoice, Failure>> confirm(String quotationId) {
    return client.post<Invoice>(
      ApiConstant.quotationConfirmUrl(quotationId),
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return _parseInvoice(data);
      },
    );
  }

  @override
  Future<Result<List<Invoice>, Failure>> invoices({
    String? customerId,
    bool pendingOnly = false,
  }) {
    final customerIdInt = customerId != null ? int.tryParse(customerId) : null;
    return client.get<List<Invoice>>(
      ApiConstant.invoicesUrl,
      params: {
        'page': 1,
        'limit': 100,
        if (customerIdInt != null && customerIdInt > 0)
          'customer_id': customerIdInt,
        if (pendingOnly) 'status': 'pending',
      },
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map) _parseInvoice(Map<String, dynamic>.from(item)),
        ]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
      },
    );
  }

  @override
  Future<Result<Invoice, Failure>> invoiceFor(String quotationId) {
    return client.get<Invoice>(
      ApiConstant.quotationInvoiceUrl(quotationId),
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return _parseInvoice(data);
      },
    );
  }

  @override
  Future<Result<Invoice, Failure>> markPaid(String invoiceId) {
    return client.post<Invoice>(
      ApiConstant.invoicePayUrl(invoiceId),
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = Map<String, dynamic>.from(map['data'] as Map);
        return _parseInvoice(data);
      },
    );
  }

  Product _parseProduct(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] ?? 'unit').toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Quotation _parseQuotation(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final number = (json['number'] ?? 'Q-$id').toString();
    final customerId = json['customer_id']?.toString() ?? '';
    final opportunityId = json['opportunity_id']?.toString();
    final ownerId =
        json['owner_id']?.toString() ?? client.currentUser?.id ?? '';
    final statusStr = (json['status'] ?? 'draft').toString().toLowerCase();
    final status = statusStr == 'confirmed'
        ? QuotationStatus.confirmed
        : QuotationStatus.draft;
    final notes = json['notes']?.toString();

    final items = <QuotationItem>[];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          items.add(
            QuotationItem(
              productId: m['product_id']?.toString(),
              description: (m['description'] ?? '').toString(),
              quantity: (m['quantity'] as num?)?.toDouble() ?? 1.0,
              unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0.0,
            ),
          );
        }
      }
    }

    final createdAt =
        CrmApiClient.parseUtcDate(json['created_at']?.toString()) ??
        DateTime.now().toUtc();
    final updatedAt =
        CrmApiClient.parseUtcDate(json['updated_at']?.toString()) ?? createdAt;

    return Quotation(
      id: id,
      number: number,
      customerId: customerId,
      opportunityId: opportunityId,
      ownerId: ownerId,
      status: status,
      notes: notes,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Invoice _parseInvoice(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final number = (json['number'] ?? 'INV-$id').toString();
    final quotationId = json['quotation_id']?.toString() ?? '';
    final customerId = json['customer_id']?.toString() ?? '';
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    final status = statusStr == 'paid'
        ? InvoiceStatus.paid
        : InvoiceStatus.pending;

    final createdAt =
        CrmApiClient.parseUtcDate(json['created_at']?.toString()) ??
        DateTime.now().toUtc();
    final dueAt =
        CrmApiClient.parseUtcDate(json['due_at']?.toString()) ??
        createdAt.add(const Duration(days: 30));
    final paidAt = CrmApiClient.parseUtcDate(json['paid_at']?.toString());

    return Invoice(
      id: id,
      number: number,
      quotationId: quotationId,
      customerId: customerId,
      amount: amount,
      status: status,
      dueAt: dueAt,
      createdAt: createdAt,
      paidAt: paidAt,
    );
  }
}
