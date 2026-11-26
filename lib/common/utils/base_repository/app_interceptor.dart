import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';
import 'package:field_crm/common/model/login_response.dart';
import 'package:field_crm/common/utils/base_repository/base_repository_setup.dart';
import 'package:field_crm/common/widgets/custom_toast.dart';
import 'package:field_crm/common/controller/login_session_controller.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';

class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.requestOptions, required this.handler});
}

class AppInterceptor extends Interceptor {
  final Ref ref;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  AppInterceptor(this.ref) : _dio = Dio();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthEndpoint =
          path.contains('/auth/login') ||
          path.contains('/auth/refresh-token') ||
          path.contains('/auth/logout') ||
          path.contains('/auth/forget-password');
      if (isAuthEndpoint) {
        super.onError(err, handler);
        return;
      }

      log("⚠️ Received 401 Unauthorized — Attempting token refresh...");

      // Skip token refresh if already in the process of logging out
      final sessionController = ref.read(loginSessionProvider.notifier);
      if (sessionController.isLoggingOut) {
        log("Already logging out. Skipping token refresh.");
        handler.reject(err);
        return;
      }

      if (_isRefreshing) {
        log("Token refresh already in progress. Queuing request...");
        _pendingRequests.add(
          _PendingRequest(requestOptions: err.requestOptions, handler: handler),
        );
        return;
      }

      _isRefreshing = true;

      try {
        final authStorage = ref.read(authStorageProvider);

        // If loginData is missing (e.g. session restored from SecureStore only
        // or Hive was cleared), still force-logout if the app thinks a user is
        // logged in or has an active token.
        if (authStorage.loginData == null) {
          final hasActiveSession =
              ref.read(authControllerProvider).valueOrNull != null ||
              (CrmApiClient.activeToken?.isNotEmpty ?? false);
          if (hasActiveSession) {
            log("No refresh data available for expired session. Logging out...");
            _handleLogout("Session expired. Please log in again.");
          } else {
            log("No active session (already logged out). Ignoring 401.");
          }
          handler.reject(err);
          _rejectPendingRequests(err);
          return;
        }

        final refreshToken = authStorage.loginData!.refreshToken;

        if (refreshToken.isEmpty) {
          log("No refresh token available. Logging out...");
          _handleLogout("Session expired. Please log in again.");
          handler.reject(err);
          return;
        }

        // Attempt to refresh the token
        final success = await _refreshAccessToken(refreshToken);

        if (success) {
          log("✅ Token refreshed successfully. Retrying original request...");

          // Retry the original failed request with new token
          final response = await _retryRequest(err.requestOptions);
          handler.resolve(response);

          // Retry all queued requests
          await _retryPendingRequests();
        } else {
          log("❌ Token refresh failed. Logging out...");
          _handleLogout("Session expired. Please log in again.");
          handler.reject(err);
          _rejectPendingRequests(err);
        }
      } catch (e, s) {
        log("Error during token refresh: $e");
        log(s.toString());
        _handleLogout("Session expired. Please log in again.");
        handler.reject(err);
        _rejectPendingRequests(err);
      } finally {
        _isRefreshing = false;
        _pendingRequests.clear();
      }
      BaseRepositorySetup.onErrorHandleTokenExpiry(err);
      return;
    }

    super.onError(err, handler);
  }

  Future<bool> _refreshAccessToken(String refreshToken) async {
    try {
      final authStorage = ref.read(authStorageProvider);
      final existingUser = authStorage.loginData?.user;
      final response = await _dio.post(
        ApiConstant.refreshTokenUrl,
        data: {"token": refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final loginResponse = LoginResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
          fallbackUser: existingUser,
        );

        await authStorage.refreshSave(loginResponse);
        CrmApiClient.setActiveToken(loginResponse.token);
        ref
            .read(authControllerProvider.notifier)
            .updateToken(loginResponse.token);
        final secure = ref.read(secureStoreProvider);
        if (await secure.read(SecureKeys.sessionToken) != null) {
          await secure.write(SecureKeys.sessionToken, loginResponse.token);
        }

        ref
            .read(loginSessionProvider.notifier)
            .setIsLogged(loginResponse.durationRemainingToExpire);

        log("New access token saved successfully");
        return true;
      }

      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 ||
          e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        log("Refresh token is invalid or expired");
      }
      return false;
    } catch (e) {
      log("Unexpected error during token refresh: $e");
      return false;
    }
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final authStorage = ref.read(authStorageProvider);
    final newToken = authStorage.loginData?.token ?? '';

    // Update the authorization header with new token
    requestOptions.headers['Authorization'] = 'Bearer $newToken';

    return _dio.fetch(requestOptions);
  }

  Future<void> _retryPendingRequests() async {
    if (_pendingRequests.isEmpty) return;

    log("Retrying ${_pendingRequests.length} pending requests...");
    final pendingList = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final pending in pendingList) {
      try {
        final response = await _retryRequest(pending.requestOptions);
        pending.handler.resolve(response);
      } on DioException catch (e) {
        pending.handler.reject(e);
      } catch (e) {
        pending.handler.reject(DioException(requestOptions: pending.requestOptions, error: e));
      }
    }
  }

  void _rejectPendingRequests(DioException err) {
    if (_pendingRequests.isEmpty) return;
    for (final pending in _pendingRequests) {
      pending.handler.reject(err);
    }
    _pendingRequests.clear();
  }

  void _handleLogout(String message) {
    try {
      // Check if already logging out to prevent re-entrant cascade
      final sessionController = ref.read(loginSessionProvider.notifier);
      if (sessionController.isLoggingOut) {
        log("Already logging out. Skipping _handleLogout.");
        return;
      }

      showCustomToast(message, ToastType.warning);

      // Use the session controller's logout which handles everything
      // (clearing storage, navigating, invalidating providers)
      sessionController.logout();
    } catch (e, s) {
      log("Error while handling logout: $e");
      log(s.toString());
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    BaseRepositorySetup.onResponseInterceptor(response);
    super.onResponse(response, handler);
  }
}
