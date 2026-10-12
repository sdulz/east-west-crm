import 'package:field_crm/features/customers/domain/customer.dart';
import 'package:field_crm/features/opportunities/domain/opportunity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_results.freezed.dart';

@freezed
abstract class SearchResults with _$SearchResults {
  const factory SearchResults({
    @Default(<Customer>[]) List<Customer> customers,
    @Default(<Customer>[]) List<Customer> contacts,
    @Default(<Opportunity>[]) List<Opportunity> opportunities,
  }) = _SearchResults;
  const SearchResults._();

  bool get isEmpty =>
      customers.isEmpty && contacts.isEmpty && opportunities.isEmpty;
}
