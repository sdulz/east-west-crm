import 'dart:io';

import 'package:field_crm/app/providers.dart';
import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';
import 'package:field_crm/common/controller/login_session_controller.dart';
import 'package:field_crm/common/model/login_response.dart';
import 'package:field_crm/common/utils/custom_multi_part/custom_multi_part.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:field_crm/features/auth/domain/app_user.dart';
import 'package:field_crm/features/auth/domain/auth_repository.dart';
import 'package:field_crm/features/auth/domain/session.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.client);

  final CrmApiClient client;

  @override
  Future<Result<Session, Failure>> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final trimmedEmail = email.trim();
    final r = await client.post<LoginResponse>(
      ApiConstant.loginUrl,
      auth: false,
      body: {
        'email': trimmedEmail,
        'password': password,
      },
      fieldMap: const {
        'email': 'email',
        'password': 'password',
      },
      parse: (raw) => LoginResponse.fromJson(
        Map<String, dynamic>.from(raw as Map),
      ),
    );

    return switch (r) {
      Err(:final error) => Err(error),
      Ok(value: final loginRes) => () async {
        CrmApiClient.setActiveToken(loginRes.token);
        _persistAuthStorage(loginRes, rememberMe ? trimmedEmail : null);

        final userMap = loginRes.user ?? <String, dynamic>{'email': trimmedEmail};
        var user = client.parseUser(userMap);

        // Fetch full profile if user details were minimal
        final profileRes = await fetchProfile();
        if (profileRes case Ok(value: final profileUser)) {
          user = profileUser;
        }

        _setCurrentUser(user);
        return Ok<Session, Failure>(Session(token: loginRes.token, user: user));
      }(),
    };
  }

  /// Calls `GET /api/v1/profile` and parses the `UserResponse`.
  Future<Result<AppUser, Failure>> fetchProfile() {
    return client.get<AppUser>(
      ApiConstant.profileUrl,
      parse: (raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        final data = map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
        final user = client.parseUser(data);
        _updateStoredUserMap(data);
        return user;
      },
    );
  }

  /// Calls `POST /api/v1/auth/refresh-token` with a refresh token.
  Future<Result<LoginResponse, Failure>> refreshTokens(String refreshToken) {
    return client.post<LoginResponse>(
      ApiConstant.refreshTokenUrl,
      auth: false,
      body: {'token': refreshToken},
      parse: (raw) {
        Map<String, dynamic>? existingUser;
        try {
          existingUser = client.ref.read(authStorageProvider).loginData?.user;
        } on Object {
          existingUser = null;
        }
        final updated = LoginResponse.fromJson(
          Map<String, dynamic>.from(raw as Map),
          fallbackUser: existingUser,
        );
        CrmApiClient.setActiveToken(updated.token);
        _persistAuthStorage(updated, null, isRefresh: true);
        return updated;
      },
    );
  }

  @override
  Future<Result<Session?, Failure>> restoreSession(String token) async {
    CrmApiClient.setActiveToken(token);
    final r = await fetchProfile();
    return switch (r) {
      Ok(value: final user) => () {
        _setCurrentUser(user);
        final currentToken = client.bearerToken ?? token;
        return Ok<Session?, Failure>(Session(token: currentToken, user: user));
      }(),
      Err(error: PermissionDeniedFailure()) => () {
        CrmApiClient.setActiveToken(null);
        return const Ok<Session?, Failure>(null);
      }(),
      Err(:final error) => Err(error),
    };
  }

  @override
  Future<Result<void, Failure>> logout(String token) async {
    CrmApiClient.setActiveToken(token);
    await client.post<void>(
      ApiConstant.logoutUrl,
      parse: (_) {},
    );
    CrmApiClient.setActiveToken(null);
    client.currentUser = null;
    try {
      client.ref.read(authStorageProvider).logout();
    } on Object {
      // Ignore if local storage is not initialized
    }
    try {
      client.ref.read(mockStoreProvider).setCurrentUser(null);
    } on Object {
      // Ignore if mock store is not initialized
    }
    return const Ok(null);
  }

  @override
  Future<Result<AppUser, Failure>> updateProfile({
    required String name,
    String? phone,
    String? avatarPath,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      return const Err(
        Failure.validation('Name must be at least 3 characters', field: 'name'),
      );
    }

    final me = client.currentUser;
    Map<String, dynamic>? storedUser;
    try {
      storedUser = client.ref.read(authStorageProvider).loginData?.user;
    } on Object {
      storedUser = null;
    }

    final email = me?.email ?? (storedUser?['email'] ?? '').toString();
    final address = storedUser?['address'] as String?;

    final hasLocalImage = avatarPath != null &&
        avatarPath.trim().isNotEmpty &&
        !avatarPath.startsWith('http://') &&
        !avatarPath.startsWith('https://') &&
        !avatarPath.startsWith('/');

    const fieldMap = {
      'name': 'name',
      'email': 'email',
      'phone': 'phone',
      'address': 'address',
      'image': 'name',
    };

    Result<void, Failure> updateRes;
    if (hasLocalImage) {
      final formData = await CustomMultipart.awaitParseBody(
        {
          'name': trimmedName,
          'email': email,
          'phone': phone,
          'address': address,
          'image': File(avatarPath),
        },
        removeNull: true,
      );
      updateRes = await client.post<void>(
        ApiConstant.profileUpdateUrl,
        body: formData,
        isMultipart: true,
        fieldMap: fieldMap,
        parse: (_) {},
      );
    } else {
      updateRes = await client.post<void>(
        ApiConstant.profileUpdateUrl,
        body: {
          'name': trimmedName,
          'email': email,
          'phone': phone,
          'address': address,
        },
        fieldMap: fieldMap,
        parse: (_) {},
      );
    }

    if (updateRes case Err(:final error)) {
      return Err(error);
    }

    final refreshed = await fetchProfile();
    if (refreshed case Ok(value: final updatedUser)) {
      final merged = hasLocalImage && updatedUser.avatarPath == null
          ? updatedUser.copyWith(avatarPath: avatarPath)
          : updatedUser;
      _setCurrentUser(merged);
      return Ok(merged);
    }

    final fallback = (me ??
            AppUser(
              id: '1',
              name: trimmedName,
              email: email,
              role: UserRole.supervisor,
              teamId: '1',
              permissions: CrmApiClient.defaultApiPermissions,
            ))
        .copyWith(
          name: trimmedName,
          phone: phone,
          avatarPath: avatarPath,
        );
    _setCurrentUser(fallback);
    return Ok(fallback);
  }

  @override
  Future<Result<void, Failure>> changePassword({
    required String current,
    required String next,
  }) {
    if (next.length < 6) {
      return Future.value(
        const Err(
          Failure.validation(
            'Use at least 6 characters',
            field: 'next',
          ),
        ),
      );
    }
    return client.post<void>(
      ApiConstant.changePasswordUrl,
      body: {
        'old_password': current,
        'password': next,
      },
      fieldMap: const {
        'old_password': 'current',
        'password': 'next',
      },
      parse: (_) {},
    );
  }

  @override
  Future<Result<String?, Failure>> requestPasswordReset(String email) {
    return client.post<String?>(
      ApiConstant.forgotPasswordUrl,
      auth: false,
      body: {'email': email.trim()},
      fieldMap: const {'email': 'email'},
      parse: (_) => null,
    );
  }

  @override
  Future<Result<void, Failure>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    // Password reset in East West CRM is handled via the email link sent by
    // POST /api/v1/auth/forget-password.
    return const Ok(null);
  }

  void _setCurrentUser(AppUser user) {
    client.currentUser = user;
    client.usersById[user.id] = user;
    try {
      final store = client.ref.read(mockStoreProvider);
      final idx = store.state.users.indexWhere((u) => u.id == user.id);
      if (idx >= 0) {
        store.state.users[idx] = user;
      } else {
        store.state.users.add(user);
      }
      store.setCurrentUser(user.id);
    } on Object {
      // Ignore if mockStoreProvider is not active
    }
  }

  void _persistAuthStorage(
    LoginResponse loginRes,
    String? rememberMeEmail, {
    bool isRefresh = false,
  }) {
    try {
      final authStorage = client.ref.read(authStorageProvider);
      if (isRefresh) {
        authStorage.refreshSave(loginRes);
      } else {
        authStorage.loginSave(loginRes, rememberMeEmail);
      }
      client.ref
          .read(loginSessionProvider.notifier)
          .setIsLogged(
            loginRes.durationRemainingToExpire,
            isNewLogin: !isRefresh,
          );
    } on Object {
      // Ignore in isolated unit test environments without localStorageProvider
    }
  }

  void _updateStoredUserMap(Map<String, dynamic> userMap) {
    try {
      final authStorage = client.ref.read(authStorageProvider);
      final current = authStorage.loginData;
      if (current != null) {
        authStorage.refreshSave(
          LoginResponse(
            token: current.token,
            refreshToken: current.refreshToken,
            message: current.message,
            expiresAt: current.expiresAt,
            user: userMap,
          ),
        );
      }
    } on Object {
      // Ignore
    }
  }
}

