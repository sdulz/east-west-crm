import 'dart:math';

import 'package:field_crm/core/mock/mock_store.dart';
import 'package:field_crm/core/mock/mock_validation.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/core/uuid.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
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

  @override
  Future<Result<AppUser, Failure>> updateProfile({
    required String name,
    String? phone,
    String? avatarPath,
  }) => store.call(() {
    final me = store.currentUser;
    MockValidation.required(name, 'name', 'Name');
    MockValidation.phone(phone);
    final i = store.state.users.indexWhere((u) => u.id == me.id);
    final saved = me.copyWith(
      name: name.trim(),
      phone: phone,
      avatarPath: avatarPath,
    );
    store.state.users[i] = saved;
    return saved;
  }, write: true);

  @override
  Future<Result<void, Failure>> changePassword({
    required String current,
    required String next,
  }) => store.call(() {
    final me = store.currentUser;
    if (store.state.passwords[me.email] != current) {
      throw const MockFailure(
        Failure.validation('Current password is wrong', field: 'current'),
      );
    }
    _checkNewPassword(next);
    store.state.passwords[me.email] = next;
  }, write: true);

  @override
  Future<Result<String?, Failure>> requestPasswordReset(String email) =>
      store.call(() {
        final user = store.state.users
            .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
            .firstOrNull;
        if (user == null) return null; // never reveal whether an email exists
        final code = (100000 + Random().nextInt(900000)).toString();
        store.state.passwordResets[user.email] = code;
        return code;
      }, write: true);

  @override
  Future<Result<void, Failure>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => store.call(() {
    final key = store.state.users
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
        .firstOrNull
        ?.email;
    if (key == null || store.state.passwordResets[key] != code.trim()) {
      throw const MockFailure(
        Failure.validation('invalid_code', field: 'code'),
      );
    }
    _checkNewPassword(newPassword);
    store.state.passwords[key] = newPassword;
    store.state.passwordResets.remove(key);
  }, write: true);

  static void _checkNewPassword(String v) {
    if (v.length < 8) {
      throw const MockFailure(
        Failure.validation('Use at least 8 characters', field: 'next'),
      );
    }
  }
}
