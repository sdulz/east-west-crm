import 'package:field_crm/common/model/paginated_data.dart';
import 'package:field_crm/common/model/pagination_response_setup.dart';

class PaginationResponse<T> {
  T data;
  bool haveNext;
  int pageIndex;

  PaginationResponse({
    required this.data,
    required Map response,
    required this.pageIndex,
  }) : haveNext = PaginationResponseSetup.haveNext(response, pageIndex);

  PaginationResponse.fromState({
    required this.data,
    required this.haveNext,
    required this.pageIndex,
  });

  factory PaginationResponse.fromJson({
    required Map<String, dynamic> response,
    required T data,
    required int pageIndex,
    required int pageSize,
  }) {
    // Detect whether the API included any standard pagination metadata.
    final bool foundPaginationKey =
        response.containsKey('lastPage') ||
        (response['data'] is Map &&
            (response['data'] as Map).containsKey('totalPages'));

    bool hasNext = false;
    try {
      if (foundPaginationKey) {
        // Use the server-provided pagination metadata.
        hasNext = PaginationResponseSetup.haveNext(response, pageIndex);
      }
    } catch (_) {
      // If parsing metadata fails for any reason, fall through to count-based.
    }

    // No standard pagination key found — fall back to item count vs page size.
    // If the returned list is exactly pageSize items, assume there's a next page.
    if (!foundPaginationKey) {
      if (data is List) {
        hasNext = (data as List).length >= pageSize;
      } else if (data is PaginatedData) {
        hasNext = (data as PaginatedData).items.length >= pageSize;
      }
    }

    return PaginationResponse.fromState(
      data: data,
      haveNext: hasNext,
      pageIndex: pageIndex,
    );
  }

  static Map<String, dynamic> params(int pageIndex, {int? pageSize}) {
    return PaginationResponseSetup.params(
      pageIndex,
      pageSize ?? PaginationResponseSetup.pageSize,
    );
  }

  static Map<String, dynamic> customParams({
    required int pageIndex,
    required int pageSize,
  }) {
    return PaginationResponseSetup.params(pageIndex, pageSize);
  }

  ///[oldPlusNew] is the data to be shown on pagination success which stores previous page data
  ///plus newly fetched page data.
  ///This data must be in order as per how to show in the UI, else newly added page data will be added on reverse order
  PaginationResponse<T> oldPlusNew(T data) {
    return PaginationResponse.fromState(
      data: data,
      haveNext: haveNext,
      pageIndex: pageIndex,
    );
  }
}
