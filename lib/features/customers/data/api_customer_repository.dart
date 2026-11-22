import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/customers/domain/customer_repository.dart';

class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository(this.client);

  final CrmApiClient client;

  static const Map<String, String> _fieldMap = {
    'name': 'name',
    'type': 'name',
    'phone': 'phone',
    'mobile': 'phone',
    'email': 'email',
    'street': 'address',
    'street2': 'address',
    'city': 'city',
    'zip': 'address',
    'country': 'country',
    'vat': 'taxId',
    'company_id': 'parentId',
  };

  @override
  Future<Result<List<Customer>, Failure>> list({String? query}) {
    final search = (query == null || query.trim().isEmpty) ? null : query.trim();
    return client.get<List<Customer>>(
      ApiConstant.customersUrl,
      params: {
        'page': 1,
        'limit': 100,
        if (search != null) 'search': search,
      },
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = map['data'] is List ? map['data'] as List : const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseCustomer(Map<String, dynamic>.from(item)),
        ];
      },
    );
  }

  @override
  Future<Result<Customer, Failure>> getById(String id) {
    return client.get<Customer>(
      ApiConstant.customerByIdUrl(id),
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        return client.parseCustomer(data);
      },
    );
  }

  @override
  Future<Result<Customer, Failure>> create(Customer customer) {
    final companyId = !customer.isCompany && customer.parentId != null
        ? int.tryParse(customer.parentId!)
        : null;
    return client.post<Customer>(
      ApiConstant.customersUrl,
      body: {
        'name': customer.name.trim(),
        'type': customer.isCompany ? 'company' : 'individual',
        'phone': customer.phone,
        'email': customer.email,
        'street': customer.address,
        'city': customer.city,
        'country': customer.country,
        if (customer.taxId != null) 'vat': customer.taxId,
        if (companyId != null) 'company_id': companyId,
      },
      fieldMap: _fieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        return client.parseCustomer(data);
      },
    );
  }

  @override
  Future<Result<Customer, Failure>> update(
    Customer customer, {
    required DateTime expectedUpdatedAt,
  }) {
    final companyId = !customer.isCompany && customer.parentId != null
        ? int.tryParse(customer.parentId!)
        : null;
    return client.put<Customer>(
      ApiConstant.customerByIdUrl(customer.id),
      body: {
        'name': customer.name.trim(),
        'type': customer.isCompany ? 'company' : 'individual',
        'phone': customer.phone,
        'email': customer.email,
        'street': customer.address,
        'city': customer.city,
        'country': customer.country,
        'vat': customer.taxId,
        'company_id': companyId,
      },
      fieldMap: _fieldMap,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        return client.parseCustomer(data);
      },
    );
  }
}

