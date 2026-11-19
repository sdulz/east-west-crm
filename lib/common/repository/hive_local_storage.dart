import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

import 'local_storage.dart';

class HiveLocalStorage implements LocalStorage {
  static const String _boxName = "LocalStorage";

  HiveLocalStorage._(this._hiveBox);

  ///In case of any error, the app does not crash but causes logical error.
  /// No data will be stored in local storage.
  final Box? _hiveBox;

  static Future<HiveLocalStorage> init() async {
    await Hive.initFlutter();
    Box? hiveBox;
    try {
      hiveBox = await Hive.openBox(_boxName);
    } catch (e, s) {
      log("Failed to set hive box");
      log(e.toString());
      log(s.toString());
    }
    assert(hiveBox != null, "Hive box must not be null");
    return HiveLocalStorage._(hiveBox);
  }

  @override
  T? get<T>(String key) {
    final value = _hiveBox?.get(key);
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }

  @override
  Future<void> put<T>(String key, T value) async {
    await _hiveBox?.put(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _hiveBox?.delete(key);
  }
}
