import 'dart:async';
import 'package:field_crm/app/bootstrap.dart';
import 'package:field_crm/common/repository/hive_local_storage.dart';
import 'package:field_crm/common/widgets/custom_system_chrome.dart';
import 'package:flutter/material.dart';


export 'package:field_crm/app/app.dart' show MyApp, FieldCrmApp;

/// Primary entry point for Field CRM, configured following the name_app architecture.
///
/// Features:
/// - Custom painting image cache tuning (80 entries / 48 MB)
/// - System UI Chrome & orientation locking (CustomSystemChrome)
/// - Offline Hive local storage initialization
/// - Full CRM bootstrap (Drift encrypted DB, Riverpod, Sentry, offline queue)
///
/// Environment configuration:
/// - Default: `flutter run`
/// - Dev: `flutter run --dart-define-from-file=env/dev.json`
/// - UAT: `flutter run --dart-define-from-file=env/uat.json`
/// - Prod: `flutter run --dart-define-from-file=env/prod.json`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 80
    ..maximumSizeBytes = 48 << 20;

  await CustomSystemChrome.setDefault();

  final hiveLocalStorage = await HiveLocalStorage.init();

  await bootstrap(hiveStorage: hiveLocalStorage);
}

