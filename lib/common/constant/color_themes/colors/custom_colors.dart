import 'package:flutter/material.dart';
import 'package:field_crm/common/constant/theme_constant.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

abstract class CustomColors {
  String get themeName;
  Color get primaryLight;
  Color get secondaryLight;

  Color get primaryDark;
  Color get secondaryDark;

  ThemeData getLightTheme(BuildContext context) {
    return ThemeConstant.lightTheme(context).copyWith(
      colorScheme: ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryLight,
        foregroundColor: ColorConstant.white,
      ),
    );
  }

  ThemeData getDarkTheme(BuildContext context) {
    return ThemeConstant.darkTheme(context).copyWith(
      colorScheme: ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: ColorConstant.white,
      ),
    );
  }
}
