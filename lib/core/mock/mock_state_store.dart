/// Where the mock persists its snapshot between launches.
abstract interface class MockStateStore {
  Future<String?> load();
  Future<void> save(String json);
  Future<void> clear();
}

class InMemoryMockStateStore implements MockStateStore {
  String? _json;
  @override
  Future<String?> load() async => _json;
  @override
  Future<void> save(String json) async => _json = json;
  @override
  Future<void> clear() async => _json = null;
}
