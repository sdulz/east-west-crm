import 'package:field_crm/common/model/login_response.dart';
import 'package:field_crm/common/repository/local_storage.dart';

class AuthLocalStorage {
  static const String _loginKey = "Login";
  static const String _fingerprintDetailsKey = "FingerprintDetails";
  static const String _fingerprintUsernameSubKey = "username";
  static const String _fingerprintPasswordSubKey = "password";
  static const String _selectedPackageKey = 'selected_package_id';
  static const String _rememberMeKey = "RememberMe";
  static const String _isFirstTimeKey = "IsFirstTime";
  static const String _instituteSelectedKey = 'HasSelectedInstitute';

  /// Pending course order draft from the package buy flow (Hive).
  static const String cachedCourseOrderKey = 'cached_course_order_v1';

  final LocalStorage _storage;

  AuthLocalStorage({required LocalStorage localStorage})
    : _storage = localStorage;

  Future<void> loginSave(
    LoginResponse loginModel,
    String? rememberMeUsername,
  ) async {
    await refreshSave(loginModel);
    await _storage.put(_rememberMeKey, rememberMeUsername);
  }

  Future<void> refreshSave(LoginResponse loginModel) async {
    await _storage.put(_loginKey, loginModel.toJson());
  }

  LoginResponse? get loginData {
    final value = _storage.get(_loginKey);
    if (value == null) return null;
    final map = Map<String, dynamic>.from(value);
    return LoginResponse.fromJson(map);
  }

  String? get rememberMeUsername {
    return _storage.get(_rememberMeKey);
  }

  Future<void> saveFingerprint({
    required String username,
    required String password,
  }) async {
    await _storage.put(_fingerprintDetailsKey, {
      _fingerprintUsernameSubKey: username,
      _fingerprintPasswordSubKey: password,
    });
  }

  bool get fingerPrintSaved => _storage.get(_fingerprintDetailsKey) != null;

  String? get fingerPrintPassword {
    return _storage.get(_fingerprintDetailsKey)?[_fingerprintPasswordSubKey];
  }

  String? get fingerPrintUsername {
    return _storage.get(_fingerprintDetailsKey)?[_fingerprintUsernameSubKey];
  }

  Future deleteFingerPrint() async {
    return await _storage.delete(_fingerprintDetailsKey);
  }

  void clearCachedCourseOrder() {
    _storage.delete(cachedCourseOrderKey);
  }

  void logout() {
    _storage.delete(_loginKey);
    _storage.delete(_instituteSelectedKey);
    _storage.delete(_selectedPackageKey);
    clearCachedCourseOrder();
  }

  void changeFirstTime() {
    _storage.put(_isFirstTimeKey, false);
  }

  bool get hasSelectedInstitute {
    return _storage.get(_instituteSelectedKey) ?? false;
  }

  Future<void> setInstituteSelected() async {
    await _storage.put(_instituteSelectedKey, true);
  }

  Future<void> saveSelectedPackage(String packageId) async {
    await _storage.put(_selectedPackageKey, packageId);
  }

  String? get selectedPackageId {
    return _storage.get(_selectedPackageKey);
  }

  bool get isFirstTime {
    return _storage.get(_isFirstTimeKey) ?? true;
  }

  bool get isLogged {
    final loginData = this.loginData;
    return loginData != null && loginData.isNotExpired;
  }
}
