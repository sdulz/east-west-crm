import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/common/repository/auth_storage.dart';
import 'package:field_crm/common/repository/local_storage.dart';

final localStorageProvider = Provider<LocalStorage>(
  (ref) => throw UnimplementedError("Local Storage is not implemented"),
);

final authStorageProvider = Provider<AuthLocalStorage>(
  (ref) => AuthLocalStorage(
    localStorage: ref.watch(localStorageProvider),
  ),
);
