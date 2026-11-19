import '../utils/environment_config.dart';

class BaseAPIConstant {
  final String stagURL;
  final String uatURL;
  final String prodURL;
  final String localUrl;

  const BaseAPIConstant({
    required this.stagURL,
    required this.prodURL,
    required this.uatURL,
    required this.localUrl,
  });

  String get baseUrl => EnvironmentConfig.when(
        staging: stagURL,
        uat: uatURL,
        prod: prodURL,
        local: localUrl,
      );

  String get appVersion => EnvironmentConfig.when(
        staging: _stagVersion,
        uat: _uatVersion,
        prod: _prodVersion,
        local: "Local",
      );



  static void setProdVersion(version) {
    _prodVersion = version;
  }

  static String _prodVersion = "";
  static final String _stagVersion =
      "{{--stag--}}"; // (Warning) Never ever change this it will affect automation
  static final String _uatVersion =
      "{{--uat--}}"; // (Warning) Never ever change this it will affect automation
}
