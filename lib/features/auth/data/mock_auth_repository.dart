import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/features/auth/domain/auth_repository.dart';
import 'package:field_crm/features/auth/domain/session.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.store);
  final MockStore store;

  static const invalidCredentials = 'invalid_credentials';
  static const inactiveAccount = 'inactive_account';

  @override
  Future<Result<Session, Failure>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) => store.call(() async {
    final user = store.state.users
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
        .firstOrNull;
    if (user == null || store.state.passwords[user.email] != password) {
      throw const MockFailure(Failure.validation(invalidCredentials));
    }
    if (!user.isActive) {
      throw const MockFailure(Failure.validation(inactiveAccount));
    }
    final token = uuidV4();
    if (rememberMe) store.state.sessions[token] = user.id;
    store.setCurrentUser(user.id);
    return Session(token: token, user: user);
  }, write: true);

  @override
  Future<Result<Session?, Failure>> restoreSession(String token) =>
      store.call(() {
        final userId = store.state.sessions[token];
        final user = store.state.users.where((u) => u.id == userId).firstOrNull;
        if (user == null || !user.isActive) return null;
        store.setCurrentUser(user.id);
        return Session(token: token, user: user);
      });

  @override
  Future<Result<void, Failure>> logout(String token) => store.call(() {
    store.state.sessions.remove(token);
    store.setCurrentUser(null);
  }, write: true);
}
