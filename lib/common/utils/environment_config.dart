import 'package:flutter/foundation.dart';

enum EnvironmentType {
  staging,
  local,
  prod,
  uat;


}

class EnvironmentConfig {
  static bool get isStaging=>type==EnvironmentType.staging;
  static bool get isProd=>type==EnvironmentType.prod;
  static bool get isLocal=>type==EnvironmentType.local;
  static bool get isUat=>type==EnvironmentType.uat;

  static const String _uat="uat";
  static const String _prod="prod";
  static const String _staging="staging";
  static const String _local="local";
  static const String _type =
      String.fromEnvironment('APIType', defaultValue: kDebugMode?_staging:_prod);

  static EnvironmentType get type {
    return switch (_type) {
       _uat=> EnvironmentType.uat,
       _prod=> EnvironmentType.prod,
       _staging=> EnvironmentType.staging,
      _local=> EnvironmentType.local,
      _ => EnvironmentType.staging,
    };
  }

  static T when<T>({
    required T uat,
    required T staging,
    required T prod,
    required T local,
  }) {
    return switch (type) {
      EnvironmentType.uat => uat,
      EnvironmentType.staging => staging,
      EnvironmentType.prod => prod,
      EnvironmentType.local => local,
    };
  }
}
