// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

// /// Notifier that manages dark mode state
// class DarkModeNotifier extends StateNotifier<bool> {
//   DarkModeNotifier() : super(false);

//   void updateFromContext(BuildContext context) {
//     final brightness = MediaQuery.of(context).platformBrightness;
//     final isDark = brightness == Brightness.dark;
    
//     if (state != isDark) {
//       state = isDark;
//       // Update the static ColorConstantDark
//       ColorConstant.isDarkMode = isDark;
//     }
//   }
  
//   void setDarkMode(bool value) {
//     state = value;
//     ColorConstant.isDarkMode = value;
//   }
// }

// /// Provider that watches system brightness and updates ColorConstantDark.isDarkMode
// final darkModeNotifierProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
//   return DarkModeNotifier();
// });