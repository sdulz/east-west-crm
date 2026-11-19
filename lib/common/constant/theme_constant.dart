import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

import 'package:field_crm/common/constant/color_constant_white_mode.dart';

class ThemeConstant {
  ThemeConstant._();

  static ThemeData darkTheme(BuildContext context) {
    final textTheme = GoogleFonts.publicSansTextTheme().apply(
      bodyColor: ColorConstant.normalTextColor,
      displayColor: ColorConstant.normalTextColor,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,

      primaryColor: ColorConstant.primaryColor,
      scaffoldBackgroundColor: ColorConstant.scaffoldBackgroundColor,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: ColorConstant.primaryColor,
        onPrimary: ColorConstant.white,
        secondary: ColorConstant.successGreen,
        onSecondary: ColorConstant.white,
        error: ColorConstant.errorRed,
        onError: ColorConstant.white,
        surface: ColorConstant.surfaceDark,
        onSurface: ColorConstant.normalTextColor,
      ),

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: ColorConstant.primaryColor,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: ColorConstant.transparent,
        titleTextStyle: GoogleFonts.publicSans(
          color: ColorConstant.textDark,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
        iconTheme:  IconThemeData(color: ColorConstant.textDark),
      ),

      checkboxTheme: CheckboxThemeData(
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(color: ColorConstant.borderColor, width: 1.0),
        ),
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(WidgetState.selected)
                  ? ColorConstant.primaryColor
                  : ColorConstant.textFormColor,
        ),
        overlayColor: WidgetStateProperty.all(ColorConstant.transparent),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstant.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorConstant.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorConstant.primaryColor, width: 1.2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: ColorConstant.textGrey,
          fontSize: 14.sp,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstant.buttonColor,
          foregroundColor: ColorConstant.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: GoogleFonts.publicSans(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstant.primaryColor,
          side: BorderSide(color: ColorConstant.primaryColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: GoogleFonts.publicSans(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData lightTheme(BuildContext context) {
    final textTheme = GoogleFonts.publicSansTextTheme().apply(
      bodyColor: ColorConstantLight.textDark,
      displayColor: ColorConstantLight.textDark,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,

      primaryColor: ColorConstantLight.primaryColor,
      scaffoldBackgroundColor: ColorConstantLight.scaffoldBackgroundColor,

      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: ColorConstantLight.primaryColor,
        onPrimary: ColorConstant.white,
        secondary: ColorConstantLight.successGreen,
        onSecondary: ColorConstant.white,
        error: ColorConstantLight.errorRed,
        onError: ColorConstant.white,
        surface: ColorConstantLight.surface,
        onSurface: ColorConstantLight.textDark,
      ),

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: ColorConstantLight.primaryColor,
        titleTextStyle: GoogleFonts.publicSans(
          color: ColorConstant.textDark,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
        iconTheme:  IconThemeData(color: ColorConstant.textDark),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: ColorConstant.transparent,
      ),
    );
  }
}
