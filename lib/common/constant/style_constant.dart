import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class StylesConstants {
  StylesConstants._();

  static const double textScaleFactor = 1.1;

  static TextStyle get normal24w700 => _normal(24.sp, FontWeight.w700);
  static TextStyle get normal24w600 => _normal(24.sp, FontWeight.w600);
  static TextStyle get normal20w700 => _normal(20.sp, FontWeight.w700);
  static TextStyle get normal20w600 => _normal(20.sp, FontWeight.w600);
  static TextStyle get normal20w500 => _normal(20.sp, FontWeight.w500);
  static TextStyle get normal18w700 => _normal(18.sp, FontWeight.w700);
  static TextStyle get normal18w600 => _normal(18.sp, FontWeight.w600);
  static TextStyle get normal16w700 => _normal(16.sp, FontWeight.w700);
  static TextStyle get normal16w600 => _normal(16.sp, FontWeight.w600);
  static TextStyle get normal15w600 => _normal(15.sp, FontWeight.w600);
  static TextStyle get normal16w500 => _normal(16.sp, FontWeight.w500);
  static TextStyle get normal16w400 => _normal(16.sp, FontWeight.w400);
  static TextStyle get normal14w700 => _normal(14.sp, FontWeight.w700);
  static TextStyle get normal14w600 => _normal(14.sp, FontWeight.w600);
  static TextStyle get normal14w500 => _normal(14.sp, FontWeight.w500);
  static TextStyle get normal14w400 => _normal(14.sp, FontWeight.w400);
  static TextStyle get normal13w400 => _normal(13.sp, FontWeight.w400);
  static TextStyle get normal12w600 => _normal(12.sp, FontWeight.w600);
  static TextStyle get normal12w500 => _normal(12.sp, FontWeight.w500);
  static TextStyle get normal12w400 => _normal(12.sp, FontWeight.w400);
  static TextStyle get normal10w600 => _normal(10.sp, FontWeight.w600);
  static TextStyle get normal10w500 => _normal(10.sp, FontWeight.w500);
  static TextStyle get normal10w400 => _normal(10.sp, FontWeight.w400);

  static TextStyle get selectedTabLabelStyle => _normal(16.sp, FontWeight.w600);
  static TextStyle get unselectedTabLabelStyle =>
      _greyLight(16.sp, FontWeight.normal);

  static TextStyle get lectureDetailGrey12 =>
      _greyLight(12.sp, FontWeight.normal);

  static TextStyle get fontRed14w500 => TextStyle(
    fontSize: 14.sp * textScaleFactor,
    fontWeight: FontWeight.w500,
    color: ColorConstant.red,
  );
  static TextStyle get fontRed12w500 => _fontRed(12.sp, FontWeight.w500);

  // Greys
  static TextStyle get grey20w700 => _greyText(20.sp, FontWeight.w700);
  static TextStyle get grey18w500 => _greyText(18.sp, FontWeight.w500);
  static TextStyle get grey16w500 => _greyText(16.sp, FontWeight.w500);
  static TextStyle get grey14w400 => _greyText(14.sp, FontWeight.w400);
  static TextStyle get grey13w400 => _greyText(13.sp, FontWeight.w400);
  static TextStyle get grey12w400 => _greyText(12.sp, FontWeight.w400);
  static TextStyle get grey12w500 => _greyText(12.sp, FontWeight.w500);
  static TextStyle get grey11w400 => _greyText(11.sp, FontWeight.w400);

  static TextStyle get grey600_12w400 => TextStyle(
    fontSize: 12.sp * textScaleFactor,
    fontWeight: FontWeight.w400,
    color: ColorConstant.textGrey,
  );
  static TextStyle get grey700_11w400 => TextStyle(
    fontSize: 11.sp * textScaleFactor,
    fontWeight: FontWeight.w400,
    color: ColorConstant.textGrey,
  );
  static TextStyle get grey800_10w400 => TextStyle(
    fontSize: 10.sp * textScaleFactor,
    fontWeight: FontWeight.w400,
    color: ColorConstant.textGrey,
  );

  static TextStyle get primary14w600 => _fontPrimary(14.sp, FontWeight.w600);
  static TextStyle get primary14w400 => _fontPrimary(14.sp, FontWeight.w400);
  static TextStyle get primary16w700 => _fontPrimary(16.sp, FontWeight.w700);
  static TextStyle get primary16w400 => _fontPrimary(16.sp, FontWeight.w400);
  static TextStyle get primary10w600 => _fontPrimary(10.sp, FontWeight.w600);
  static TextStyle get primary14w500 => _fontPrimary(14.sp, FontWeight.w500);
  static TextStyle get primary12w500 => _fontPrimary(12.sp, FontWeight.w500);
  static TextStyle get primary12w600 => _fontPrimary(12.sp, FontWeight.w600);
  static TextStyle get primary16w600 => _fontPrimary(16.sp, FontWeight.w600);
  static TextStyle get primary13w600 => _fontPrimary(13.sp, FontWeight.w600);
  static TextStyle get primary13w500 => _fontPrimary(13.sp, FontWeight.w500);
  static TextStyle get primary24w700 => _fontPrimary(24.sp, FontWeight.w700);

  static TextStyle get fontWhite12w600 => _normal(12.sp, FontWeight.w600);
  static TextStyle get fontWhite11w700 => TextStyle(
    fontSize: 11.sp * textScaleFactor,
    fontWeight: FontWeight.w700,
    color: ColorConstant.textDark,
  );
  static TextStyle get fontWhite70_12w500 => TextStyle(
    fontSize: 12.sp * textScaleFactor,
    fontWeight: FontWeight.w500,
    color: ColorConstant.textLightColor,
  );
  static TextStyle get fontWhite30w700 => TextStyle(
    fontSize: 30.sp * textScaleFactor,
    fontWeight: FontWeight.w700,
    color: ColorConstant.textDark,
  );
  static TextStyle get fontWhite19w900 => TextStyle(
    fontSize: 19.sp * textScaleFactor,
    fontWeight: FontWeight.w900,
    color: ColorConstant.textDark,
  );
  static TextStyle get red11w700 => TextStyle(
    fontSize: 11.sp * textScaleFactor,
    fontWeight: FontWeight.w700,
    color: ColorConstant.deepRed,
  );
  static TextStyle get fontWhite70_16w500 => TextStyle(
    fontSize: 16.sp * textScaleFactor,
    fontWeight: FontWeight.w500,
    color: ColorConstant.textLightColor,
  );
  static TextStyle get fontWhite80_13w500 => TextStyle(
    fontSize: 13.sp * textScaleFactor,
    fontWeight: FontWeight.w500,
    color: ColorConstant.textLightColor, // mapped to white70 for simplicity
  );
  static TextStyle get fontWhite50_12w400 => TextStyle(
    fontSize: 12.sp * textScaleFactor,
    fontWeight: FontWeight.w400,
    color: ColorConstant.textLightColor, // mapped to white70
  );
  static TextStyle get white10w800 => TextStyle(
    fontSize: 10.sp * textScaleFactor,
    fontWeight: FontWeight.w800,
    color: ColorConstant.textDark,
  );
  static TextStyle get normal15w700 => _normal(15.sp, FontWeight.w700);
  static TextStyle get fontWhite22w700 => TextStyle(
    fontSize: 22.sp * textScaleFactor,
    fontWeight: FontWeight.w700,
    color: ColorConstant.textDark,
  );
  static TextStyle get fontWhite70_14w400 => TextStyle(
    fontSize: 14.sp * textScaleFactor,
    fontWeight: FontWeight.w400,
    color: ColorConstant.textLightColor,
  );

  static TextStyle get fontRed12w400 => _fontRed(12.sp, FontWeight.w400);
  static TextStyle get fontRed13w500 => _fontRed(13.sp, FontWeight.w500);

  static TextStyle get textFieldIconColor14w400 => TextStyle(
    fontSize: 14.sp * textScaleFactor,
    fontWeight: FontWeight.w400,
    color: ColorConstant.textGrey,
  );

  static TextStyle get hintGrey14w400 => TextStyle(
    fontSize: 14.sp * textScaleFactor,
    fontWeight: FontWeight.w400,
    color: ColorConstant.textFormColor,
  );

  // Accents
  static TextStyle get orange11w500 => TextStyle(
    fontSize: 11.sp * textScaleFactor,
    fontWeight: FontWeight.w500,
    color: ColorConstant.orange,
  );
  static TextStyle get green11w500 => TextStyle(
    fontSize: 11.sp * textScaleFactor,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF00A000), // Hex in green is fine
  );
  static TextStyle get blue12w500 => TextStyle(
    fontSize: 12.sp * textScaleFactor,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1E88E5), // Hex in blue is fine
  );

  // Private helper methods
  static TextStyle _normal(double size, FontWeight weight) {
    return TextStyle(
      fontSize: size * textScaleFactor,
      fontWeight: weight,
      color: ColorConstant.normalTextColor,
    );
  }

  static TextStyle _greyText(double fontSize, FontWeight fontWeight) {
    return TextStyle(
      fontSize: fontSize * textScaleFactor,
      fontWeight: fontWeight,
      color: ColorConstant.textGrey,
    );
  }

  static TextStyle _greyLight(double fontSize, FontWeight fontWeight) {
    return TextStyle(
      fontSize: fontSize * textScaleFactor,
      fontWeight: fontWeight,
      color: ColorConstant.greyLight,
    );
  }

  static TextStyle _fontRed(double fontSize, FontWeight fontWeight) {
    return TextStyle(
      fontSize: fontSize * textScaleFactor,
      fontWeight: fontWeight,
      color: ColorConstant.errorRed,
    );
  }

  static TextStyle _fontPrimary(double fontSize, FontWeight fontWeight) {
    return TextStyle(
      fontSize: fontSize * textScaleFactor,
      fontWeight: fontWeight,
      color: ColorConstant.primaryColor,
    );
  }
}
