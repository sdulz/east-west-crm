import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/auth/domain/session.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, Session?>(AuthController.new);

class AuthController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    final secure = ref.watch(secureStoreProvider);
    final token = await secure.read(SecureKeys.sessionToken);
    if (token == null) return null;
    if (await secure.read(SecureKeys.biometricEnabled) == 'true') {
      final bio = ref.read(biometricAuthProvider);
      if (await bio.isAvailable() && !await bio.authenticate('Unlock')) {
        return null;
      }
    }
    final r = await ref.read(authRepositoryProvider).restoreSession(token);
    final session = r.valueOrNull;
    if (session == null && r.isOk) await secure.delete(SecureKeys.sessionToken);
    return session;
  }

  Future<bool> get hasRememberedToken async =>
      await ref.read(secureStoreProvider).read(SecureKeys.sessionToken) != null;

  Future<Result<Session, Failure>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final r = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password, rememberMe: rememberMe);
    if (r case Ok(:final value)) {
      if (rememberMe) {
        await ref
            .read(secureStoreProvider)
            .write(SecureKeys.sessionToken, value.token);
      }
      state = AsyncData(value);
    }
    return r;
  }

  Future<Result<AppUser, Failure>> updateProfile({
    required String name,
    String? phone,
    String? avatarPath,
  }) async {
    final r = await ref
        .read(authRepositoryProvider)
        .updateProfile(name: name, phone: phone, avatarPath: avatarPath);
    final s = state.valueOrNull;
    if (r case Ok(:final value) when s != null) {
      state = AsyncData(s.copyWith(user: value));
    }
    return r;
  }

  Future<Result<void, Failure>> changePassword({
    required String current,
    required String next,
  }) => ref
      .read(authRepositoryProvider)
      .changePassword(current: current, next: next);

  Future<Result<String?, Failure>> requestPasswordReset(String email) =>
      ref.read(authRepositoryProvider).requestPasswordReset(email);

  Future<Result<void, Failure>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => ref
      .read(authRepositoryProvider)
      .resetPassword(email: email, code: code, newPassword: newPassword);

  void retryRestore() => ref.invalidateSelf();

  Future<void> setBiometricEnabled(bool enabled) => ref
      .read(secureStoreProvider)
      .write(SecureKeys.biometricEnabled, enabled.toString());

  Future<bool> isBiometricEnabled() async =>
      await ref.read(secureStoreProvider).read(SecureKeys.biometricEnabled) ==
      'true';

  void updateToken(String newToken) {
    final s = state.valueOrNull;
    if (s != null) {
      state = AsyncData(s.copyWith(token: newToken));
    }
  }

  /// Local-only forced logout used when a token expires (401) or refresh fails.
  /// Does not call `/auth/logout` (which would fail with 401 again) and
  /// immediately clears auth state so GoRouter redirects to `/login`.
  Future<void> forceLogout() async {
    CrmApiClient.setActiveToken(null);
    try {
      ref.read(crmApiClientProvider).currentUser = null;
    } on Object {
      // Ignore if not initialized.
    }
    try {
      ref.read(authStorageProvider).logout();
    } on Object {
      // Ignore if local storage is not initialized.
    }
    try {
      await ref.read(secureStoreProvider).delete(SecureKeys.sessionToken);
    } on Object {
      // Ignore if secure store is unavailable.
    }
    try {
      await ref.read(pendingQueueRepositoryProvider).clear();
    } on Object {
      // Ignore if database is unavailable.
    }
    ref.read(appLockProvider.notifier).unlock();
    state = const AsyncData(null);
  }

  Future<void> logout() async {
    final token = state.valueOrNull?.token;
    if (token != null) {
      try {
        await ref.read(authRepositoryProvider).logout(token);
      } on Object {
        // Always complete local logout even if the server call fails.
      }
    }
    await forceLogout();
  }
}

final currentUserProvider = Provider<AppUser?>((ref) =>
    ref.watch(authControllerProvider).valueOrNull?.user);

final permissionsProvider = Provider<Permissions>((ref) =>
    ref.watch(currentUserProvider)?.permissions ?? const Permissions());

class AppLockNotifier extends StateNotifier<bool> {
  AppLockNotifier() : super(false);
  void lock() => state = true;
  void unlock() => state = false;
}

final appLockProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) =>
    AppLockNotifier());

final currentUserIdProvider = Provider<String?>((ref) =>
    ref.watch(currentUserProvider)?.id);
