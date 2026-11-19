import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/common/model/paginated_data.dart';
import 'package:field_crm/common/model/pagination_response.dart';
import 'package:field_crm/common/utils/generic_state.dart';

class PaginationController<T>
    extends StateNotifier<GenericState<PaginatedData<T>>> {
  final Future<PaginationResponse<List<T>>> Function(int page) fetcher;

  PaginationController({required this.fetcher}) : super(Empty());

  int _page = 1;

  Future<void> loadInitial() async {
    // Only show loading spinner on first load, keep stale data visible on refresh
    if (state is! Success) state = Loading();
    _page = 1;

    try {
      final response = await fetcher(_page);

      state = Success(
        PaginatedData(
          items: response.data,
          haveNext: response.haveNext,
          pageIndex: response.pageIndex,
        ),
      );
    } catch (e) {
      state = Error(e.toString());
    }
  }

  Future<void> refresh() async {
    _page = 1;
    try {
      final response = await fetcher(_page);
      state = Success(
        PaginatedData(
          items: response.data,
          haveNext: response.haveNext,
          pageIndex: response.pageIndex,
        ),
      );
    } catch (_) {
      // ignore: empty_catches
    }
  }

  Future<void> loadMore() async {
    if (state is! Success) return;
    if (!(state as Success).data.haveNext) return;
    if ((state as Success).isPaginationLoading) return;

    final old = (state as Success).data.items;
    final oldPage = _page;

    try {
      state = Success((state as Success).data, isPaginationLoading: true);

      _page += 1;
      final response = await fetcher(_page);

      state = Success(
        PaginatedData(
          items: [...old, ...response.data],
          haveNext: response.haveNext,
          pageIndex: response.pageIndex,
        ),
      );
    } catch (_) {
      // Roll back the page so the next loadMore retries the same page.
      _page = oldPage;
      state = Success(
        PaginatedData(items: old, haveNext: true, pageIndex: oldPage),
      );
    }
  }
}
