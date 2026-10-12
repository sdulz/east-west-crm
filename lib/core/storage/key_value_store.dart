import 'package:field_crm/core/storage/app_database.dart';

/// Non-secret preferences (theme, locale). Secrets go to `SecureStore`.
abstract interface class KeyValueStore {
  Future<String?> get(String key);
  Future<void> put(String key, String value);
}

class DriftKeyValueStore implements KeyValueStore {
  DriftKeyValueStore(this.db);
  final AppDatabase db;

  @override
  Future<String?> get(String key) async => (await (db.select(
    db.keyValues,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  @override
  Future<void> put(String key, String value) => db
      .into(db.keyValues)
      .insertOnConflictUpdate(
        KeyValuesCompanion.insert(key: key, value: value),
      );
}

class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};
  @override
  Future<String?> get(String key) async => values[key];
  @override
  Future<void> put(String key, String value) async => values[key] = value;
}
