import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/app/providers.dart';
import 'package:field_crm/common/constant/api_constant.dart';
import 'package:field_crm/common/controller/local_storage_provider.dart';
import 'package:field_crm/common/model/login_response.dart';
import 'package:field_crm/common/repository/auth_storage.dart';
import 'package:field_crm/common/utils/base_repository/custom_api_exception.dart';
import 'package:field_crm/common/widgets/custom_toast.dart';
import 'package:field_crm/core/network/crm_api_client.dart';
import 'package:field_crm/core/storage/secure_store.dart';
import 'package:field_crm/features/auth/application/auth_controller.dart';

final loginSessionProvider =
    StateNotifierProvider<LoginSessionController, bool>((ref) {
  final localStorage = ref.watch(authStorageProvider);
  return LoginSessionController(
    localStorage.isLogged,
    localStorage: localStorage,
    ref: ref,
  );
});

class LoginSessionController extends StateNotifier<bool> {
  final AuthLocalStorage localStorage;
  final Ref ref;

  LoginSessionController(
    super.state, {
    required this.localStorage,
    required this.ref,
  });

  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  Timer? _timer;
  bool _isFetchingAccessToken = false;
  bool hasJustLoggedIn = false;

  void setIsLogged(Duration tillWhen, {bool isNewLogin = false}) {
    if (!mounted) return;
    state = true;
    if (isNewLogin) {
      hasJustLoggedIn = true;
    }
    _timer?.cancel();

    if (tillWhen <= Duration.zero) return;

    final refreshDuration = Duration(
      milliseconds: (tillWhen.inMilliseconds * 0.9).round(),
    );

    log(
      "Setting up token refresh timer for ${refreshDuration.inMinutes} minutes",
    );

    _timer = Timer(refreshDuration, () {
      _timer?.cancel();
      if (mounted) {
        tryFetchAccessToken();
      }
    });
  }

  Future<void> tryFetchAccessToken() async {
    if (!mounted || _isFetchingAccessToken) {
      log("Already fetching access token. New request blocked.");
      return;
    }

    log("Starting proactive access token refresh");
    _isFetchingAccessToken = true;

    try {
      final currentLoginData = localStorage.loginData;

      if (currentLoginData == null || currentLoginData.refreshToken.isEmpty) {
        throw CustomAPIException("No refresh token available", null);
      }

      final dio = Dio();
      final response = await dio.post(
        ApiConstant.refreshTokenUrl,
        data: {"token": currentLoginData.refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final newLoginResponse = LoginResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        fallbackUser: currentLoginData.user,
      );
      await localStorage.refreshSave(newLoginResponse);
      CrmApiClient.setActiveToken(newLoginResponse.token);
      ref
          .read(authControllerProvider.notifier)
          .updateToken(newLoginResponse.token);
      try {
        final secure = ref.read(secureStoreProvider);
        if (await secure.read(SecureKeys.sessionToken) != null) {
          await secure.write(SecureKeys.sessionToken, newLoginResponse.token);
        }
      } on Object {
        // Ignore if secure storage is unavailable.
      }

      setIsLogged(newLoginResponse.durationRemainingToExpire);
      log("Access token refreshed proactively");
    } catch (e, s) {
      log("Proactive token refresh failed: ${e.toString()}");
      log(s.toString());

      if (!mounted) return;
      if (e is DioException) {
        final code = e.response?.statusCode;
        if (code == 400 || code == 401 || code == 403) {
          showCustomToast(
            "Session expired. Please login again.",
            ToastType.warning,
          );
          logout();
        }
      }
    } finally {
      _isFetchingAccessToken = false;
      log("Proactive token refresh process completed");
    }
  }

  void logout() {
    if (!mounted || _isLoggingOut) return;
    _isLoggingOut = true;

    state = false;
    _timer?.cancel();
    localStorage.logout();

    // Clear Riverpod auth state & secure storage so GoRouter redirects to /login.
    unawaited(ref.read(authControllerProvider.notifier).forceLogout());

    Future.delayed(const Duration(milliseconds: 500), () {
      _isLoggingOut = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
