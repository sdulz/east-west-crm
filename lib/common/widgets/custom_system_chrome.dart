import 'package:flutter/services.dart';

class CustomSystemChrome {
  static Future<void> setDefault()async{
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,overlays:[SystemUiOverlay.top]);
  }


}
