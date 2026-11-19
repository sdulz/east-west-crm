class UniqueChecker {
  final List<String> values;
  final int? excludeIfIndex;

  UniqueChecker({
    required this.values,
    required this.excludeIfIndex,
  });

  bool isRedundant(String value) {
    final index = values.indexWhere((e) => e == value);
    if (index == -1) return false;
    if (index == excludeIfIndex) return false;
    return true;
  }
}
