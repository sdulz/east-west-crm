import 'dart:async';

import 'package:field_crm/app/providers.dart';
import 'package:field_crm/features/search/domain/search_results.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_controller.g.dart';

/// FR-MOB-003: 300 ms debounce, grouped results.
@riverpod
class SearchController extends _$SearchController {
  static const debounce = Duration(milliseconds: 300);
  Timer? _timer;
  String _query = '';

  String get query => _query;

  @override
  AsyncValue<SearchResults> build() {
    ref.onDispose(() => _timer?.cancel());
    return const AsyncData(SearchResults());
  }

  void setQuery(String q) {
    _query = q;
    _timer?.cancel();
    if (q.trim().isEmpty) {
      state = const AsyncData(SearchResults());
      return;
    }
    state = const AsyncLoading();
    _timer = Timer(debounce, () => unawaited(_run(q)));
  }

  Future<void> _run(String q) async {
    final r = await ref.read(searchRepositoryProvider).search(q);
    if (_query != q) return; // stale
    state = r.fold(AsyncData.new, (f) => AsyncError(f, StackTrace.current));
  }
}
