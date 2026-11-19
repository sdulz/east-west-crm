class PaginatedData<T> {
  final List<T> items;
  final bool haveNext;
  final int pageIndex;

  PaginatedData({
    required this.items,
    required this.haveNext,
    required this.pageIndex,
  });

  PaginatedData<T> copyWith({
    List<T>? items,
    bool? haveNext,
    int? pageIndex,
  }) {
    return PaginatedData(
      items: items ?? this.items,
      haveNext: haveNext ?? this.haveNext,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}
