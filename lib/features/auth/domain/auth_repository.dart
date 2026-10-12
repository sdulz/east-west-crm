import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/auth/domain/session.dart';

abstract interface class AuthRepository {
  Future<Result<Session, Failure>> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  /// Returns the session for a previously remembered token, or `null`.
  Future<Result<Session?, Failure>> restoreSession(String token);

  Future<Result<void, Failure>> logout(String token);

  Future<Result<AppUser, Failure>> updateProfile({
    required String name,
    String? phone,
    String? avatarPath,
  });

  Future<Result<void, Failure>> changePassword({
    required String current,
    required String next,
  });

  /// Returns the one-time code so the mock can show it; a real backend
  /// emails it and returns `null`. Unknown emails also return `null`.
  Future<Result<String?, Failure>> requestPasswordReset(String email);

  Future<Result<void, Failure>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
