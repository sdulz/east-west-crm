import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/features/search/domain/search_results.dart';

final searchControllerProvider =
    StateNotifierProvider<SearchController, AsyncValue<SearchResults>>(
  SearchController.new,
);

class SearchController extends StateNotifier<AsyncValue<SearchResults>> {
  SearchController(this.ref) : super(const AsyncData(SearchResults())) {
    ref.onDispose(() => _timer?.cancel());
  }

  final Ref ref;
  static const debounce = Duration(milliseconds: 300);
  Timer? _timer;
  String _query = '';

  String get query => _query;

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
    if (_query != q) return;
    state = r.fold(AsyncData.new, (f) => AsyncError(f, StackTrace.current));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
