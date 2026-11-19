abstract interface class LocalStorage {
  T? get<T>(String key);

  Future<void> put<T>(String key, T value);

  Future<void> delete(String key);
}

/// In-memory implementation of [LocalStorage] for tests and fallbacks.
class InMemoryLocalStorage implements LocalStorage {
  final Map<String, dynamic> _data = {};

  @override
  T? get<T>(String key) => _data[key] as T?;

  @override
  Future<void> put<T>(String key, T value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}

