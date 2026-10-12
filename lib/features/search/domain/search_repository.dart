import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/search/domain/search_results.dart';

abstract interface class SearchRepository {
  /// Matches name, phone and email, case-insensitively.
  Future<Result<SearchResults, Failure>> search(String query);
}
