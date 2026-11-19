import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:field_crm/features/search/domain/search_repository.dart';
import 'package:field_crm/features/search/domain/search_results.dart';

class ApiSearchRepository implements SearchRepository {
  ApiSearchRepository(this.client);

  final CrmApiClient client;

  @override
  Future<Result<SearchResults, Failure>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const Ok(SearchResults());

    final customersFuture = client.get<List<Customer>>(
      ApiConstant.customersUrl,
      params: {'page': 1, 'limit': 50, 'search': q},
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseCustomer(Map<String, dynamic>.from(item)),
        ];
      },
    );

    final leadsFuture = client.get<List<Opportunity>>(
      ApiConstant.crmLeadsUrl,
      params: {'page': 1, 'limit': 50, 'search': q},
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final list = (map['data'] as List?) ?? const [];
        return [
          for (final item in list)
            if (item is Map)
              client.parseLead(Map<String, dynamic>.from(item)),
        ];
      },
    );

    final customersRes = await customersFuture;
    if (customersRes case Err(:final error)) return Err(error);

    final leadsRes = await leadsFuture;
    if (leadsRes case Err(:final error)) return Err(error);

    final allCustomers = (customersRes as Ok<List<Customer>, Failure>).value;
    final opportunities = (leadsRes as Ok<List<Opportunity>, Failure>).value;

    return Ok(
      SearchResults(
        customers: allCustomers.where((c) => c.isCompany).toList(),
        contacts: allCustomers.where((c) => !c.isCompany).toList(),
        opportunities: opportunities,
      ),
    );
  }
}

