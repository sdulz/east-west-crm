import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:field_crm/core/mock/mock_state_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

part 'app_database.g.dart';

@pragma('vm:entry-point')
void _setupSqlCipher() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

/// Encrypted local store. Holds only the pending-write queue and the mock's
/// snapshot — it is not an offline cache of server data.
@DataClassName('PendingWriteRow')
class PendingWrites extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  TextColumn get targetId => text()();
  TextColumn get status => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get label => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('KeyValueRow')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [PendingWrites, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens (or creates) the SQLCipher-encrypted file database.
  factory AppDatabase.open({required String name, required String key}) {
    _setupSqlCipher();
    return AppDatabase(
      LazyDatabase(() async {
        await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, '$name.sqlite'));
        return NativeDatabase.createInBackground(
          file,
          isolateSetup: _setupSqlCipher,
          setup: (db) => applyKey(db, key),
        );
      }),
    );
  }



  @override
  int get schemaVersion => 1;

  /// Sets the encryption key and verifies the binary really is SQLCipher.
  static void applyKey(dynamic db, String key) {
    // `db` is a sqlite3 `Database`; typed dynamically to keep sqlite3 out of
    // the import graph of widget tests that only need the in-memory executor.
    // ignore: avoid_dynamic_calls, reason above
    db.execute("pragma key = '${key.replaceAll("'", "''")}'");
    // ignore: avoid_dynamic_calls, reason above
    final rows = db.select('pragma cipher_version') as List;
    if (rows.isEmpty && (Platform.isAndroid || Platform.isIOS)) {
      throw StateError('SQLCipher is not available; refusing unencrypted DB');
    }
  }
}

class DriftMockStateStore implements MockStateStore {
  DriftMockStateStore(this.db);
  final AppDatabase db;
  static const _key = 'mock_state';

  @override
  Future<String?> load() async {
    final row = await (db.select(
      db.keyValues,
    )..where((t) => t.key.equals(_key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> save(String json) => db
      .into(db.keyValues)
      .insertOnConflictUpdate(
        KeyValuesCompanion.insert(key: _key, value: json),
      );

  @override
  Future<void> clear() =>
      (db.delete(db.keyValues)..where((t) => t.key.equals(_key))).go();
}
