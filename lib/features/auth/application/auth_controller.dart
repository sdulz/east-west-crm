import 'package:field_crm/app/providers.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/auth/domain/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_controller.g.dart';

/// FR-MOB-001. `null` means logged out.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<Session?> build() async {
    final secure = ref.watch(secureStoreProvider);
    final token = await secure.read(SecureKeys.sessionToken);
    if (token == null) return null;
    if (await secure.read(SecureKeys.biometricEnabled) == 'true') {
      final bio = ref.read(biometricAuthProvider);
      if (await bio.isAvailable() && !await bio.authenticate('Unlock')) {
        // Token stays; the login screen offers "Unlock with biometrics".
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
    final s = state.value;
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

  /// Re-run the restore flow (used by "Unlock with biometrics").
  void retryRestore() => ref.invalidateSelf();

  Future<void> setBiometricEnabled(bool enabled) => ref
      .read(secureStoreProvider)
      .write(SecureKeys.biometricEnabled, enabled.toString());

  Future<bool> isBiometricEnabled() async =>
      await ref.read(secureStoreProvider).read(SecureKeys.biometricEnabled) ==
      'true';

  /// Wipes session and the pending queue (FR-MOB-001).
  Future<void> logout() async {
    final token = state.value?.token;
    if (token != null) await ref.read(authRepositoryProvider).logout(token);
    await ref.read(secureStoreProvider).delete(SecureKeys.sessionToken);
    await ref.read(pendingQueueRepositoryProvider).clear();
    state = const AsyncData(null);
  }
}

@riverpod
AppUser? currentUser(Ref ref) => ref.watch(authControllerProvider).value?.user;

@riverpod
Permissions permissions(Ref ref) =>
    ref.watch(currentUserProvider)?.permissions ?? const Permissions();

/// Inactivity lock. The router redirects to the lock screen while `true`.
@Riverpod(keepAlive: true)
class AppLock extends _$AppLock {
  @override
  bool build() => false;
  void lock() => state = true;
  void unlock() => state = false;
}

@riverpod
String? currentUserId(Ref ref) => ref.watch(currentUserProvider)?.id;
