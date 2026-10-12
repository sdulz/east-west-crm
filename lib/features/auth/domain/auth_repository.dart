import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
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
}
