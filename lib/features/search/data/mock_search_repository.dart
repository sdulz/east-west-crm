import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/search/domain/search_repository.dart';
import 'package:field_crm/features/search/domain/search_results.dart';

class MockSearchRepository implements SearchRepository {
  MockSearchRepository(this.store);
  final MockStore store;

  @override
  Future<Result<SearchResults, Failure>> search(String query) => store.call(() {
    store.currentUser;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const SearchResults();
    bool hit(String? s) => s != null && s.toLowerCase().contains(q);
    final customers = store.state.customers
        .where((c) => hit(c.name) || hit(c.phone) || hit(c.email))
        .toList();
    return SearchResults(
      customers: customers.where((c) => c.isCompany).toList(),
      contacts: customers.where((c) => !c.isCompany).toList(),
      opportunities: store
          .visibleOpportunities()
          .where((o) => hit(o.title))
          .toList(),
    );
  });
}
