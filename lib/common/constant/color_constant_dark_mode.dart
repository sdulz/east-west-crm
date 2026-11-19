//
import 'package:flutter/material.dart';

import '../controller/theme_controller.dart';

class ColorConstant {
  ColorConstant._();

  // ───────── PRIMARY BRAND COLORS ─────────
  static Color get primaryColor => currentTheme.primaryColor;
  static Color get primaryDark => currentTheme.primaryDark;
  static Color get buttonColor => currentTheme.buttonColor;

  // ───────── NEUTRALS / BASICS ─────────
  static Color get white => currentTheme.white;
  static Color get white70 => currentTheme.white70;
  static Color get black => currentTheme.black;
  static Color get transparent => currentTheme.transparent;

  // ───────── BACKGROUND COLORS ─────────
  static Color get scaffoldBackgroundColor =>
      currentTheme.scaffoldBackgroundColor;
  static Color get backgroundColor => currentTheme.backgroundColor;
  static Color get secondaryBackgroundColor =>
      currentTheme.secondaryBackgroundColor;

  static Color get surfaceDarkCard => currentTheme.surfaceDarkCard;
  static Color get surfaceDark => currentTheme.surfaceDark;
  static Color get surface => currentTheme.surface;

  static Color get cardBackground => currentTheme.cardBackground;
  static Color get lectureThumbnailBackground =>
      currentTheme.lectureThumbnailBackground;
  static Color get whiteBackground => currentTheme.whiteBackground;

  // ───────── TEXT COLORS ─────────
  static Color get normalTextColor => currentTheme.normalTextColor;
  static Color get textDark => currentTheme.textDark;
  static Color get textLightColor => currentTheme.textLightColor;
  static Color get textDarkColor => currentTheme.textDarkColor;
  static Color get secondaryTextColor => currentTheme.secondaryTextColor;

  static Color get hintTextColor => currentTheme.hintTextColor;
  static Color get textWhite => currentTheme.textWhite;
  static Color get textGrey => currentTheme.textGrey;

  static Color get grey => currentTheme.grey;
  static Color get greyLight => currentTheme.greyLight;

  // ───────── BORDER / DIVIDER COLORS ─────────
  static Color get borderColor => currentTheme.borderColor;
  static Color get dividerColor => currentTheme.dividerColor;
  static Color get textFieldBorder => currentTheme.textFieldBorder;

  // ───────── INPUT FIELD COLORS ─────────
  static Color get textFormColor => currentTheme.textFormColor;
  static Color get disabledTextField => currentTheme.disabledTextField;
  static Color get textFieldIconColor => currentTheme.textFieldIconColor;

  // ───────── STATUS COLORS ─────────
  static Color get errorRed => currentTheme.errorRed;
  static Color get logoutRed => currentTheme.logoutRed;
  static Color get successGreen => currentTheme.successGreen;
  static Color get warningToast => currentTheme.warningToast;
  static Color get redMoneyColor => currentTheme.redMoneyColor;
  static Color get leafGreen => currentTheme.leafGreen;
  static Color get orange => currentTheme.orange;
  static Color get red => currentTheme.red;
  static Color get deepRed => currentTheme.deepRed;

  // ───────── SHIMMER / LOADING COLORS ─────────
  static Color get shimmerBaseColor => currentTheme.shimmerBaseColor;
  static Color get shimmerHighlightColor => currentTheme.shimmerHighlightColor;

  static Color get shimmerDark => currentTheme.shimmerDark;
  static Color get shimmerMid => currentTheme.shimmerMid;
  static Color get shimmerLight => currentTheme.shimmerLight;
  static Color get shimmerOnlyForBase => currentTheme.shimmerOnlyForBase;

  // ───────── BUTTON STATES / OVERLAYS ─────────
  static Color get buttonSoftSplash => currentTheme.buttonSoftSplash;
  static Color get buttonSoftColor => currentTheme.buttonSoftColor;
  static Color get buttonSplash => currentTheme.buttonSplash;

  // ───────── TRANSPARENCY / OVERLAYS ─────────
  static Color get overlayDark => currentTheme.overlayDark;
  static Color get overlayLight => currentTheme.overlayLight;

  // ───────── OTHERS ─────────
  static Color get bannerColor => currentTheme.bannerColor;
  static Color get cardIcon => currentTheme.cardIcon;
}

// ───────── EXTENSIONS ─────────
extension ColorHelper on Color {
  Color withCustomOpacity(double opacity) => withValues(alpha: opacity);
}

// ───────── APP COLORS INTERFACE ─────────
abstract class AppColorsTheme {
  Color get primaryColor;
  Color get primaryDark;
  Color get buttonColor;

  Color get white;
  Color get white70;
  Color get black;
  Color get transparent;

  Color get scaffoldBackgroundColor;
  Color get backgroundColor;
  Color get secondaryBackgroundColor;

  Color get surfaceDarkCard;
  Color get surfaceDark;
  Color get surface;

  Color get cardBackground;
  Color get lectureThumbnailBackground;
  Color get whiteBackground;

  Color get normalTextColor;
  Color get textDark;
  Color get textLightColor;
  Color get textDarkColor;
  Color get secondaryTextColor;

  Color get hintTextColor;
  Color get textWhite;
  Color get textGrey;

  Color get grey;
  Color get greyLight;

  Color get borderColor;
  Color get dividerColor;
  Color get textFieldBorder;

  Color get textFormColor;
  Color get disabledTextField;
  Color get textFieldIconColor;

  Color get errorRed;
  Color get logoutRed;
  Color get successGreen;
  Color get warningToast;
  Color get redMoneyColor;
  Color get leafGreen;
  Color get orange;
  Color get red;
  Color get deepRed;

  Color get shimmerBaseColor;
  Color get shimmerHighlightColor;
  Color get shimmerDark;
  Color get shimmerMid;
  Color get shimmerLight;
  Color get shimmerOnlyForBase;

  Color get buttonSoftSplash;
  Color get buttonSoftColor;
  Color get buttonSplash;

  Color get overlayDark;
  Color get overlayLight;

  Color get bannerColor;
  Color get cardIcon;
}

// ───────── INSTANCES ─────────
class AppColorConstant {
  static final AppColorsTheme dark = _DarkColors();
  static final AppColorsTheme light = _LightColors();
}

class _DarkColors implements AppColorsTheme {
  @override
  Color get primaryColor => const Color(0xFFB00C22);
  @override
  Color get primaryDark => const Color(0xff8A0A1B);
  @override
  Color get buttonColor => primaryColor;

  @override
  Color get white => Colors.white;
  @override
  Color get white70 => Colors.white70;
  @override
  Color get black => Colors.black;
  @override
  Color get transparent => Colors.transparent;

  @override
  Color get scaffoldBackgroundColor => const Color(0xFF1F2024);
  @override
  Color get backgroundColor => const Color(0xFF1F2024);
  @override
  Color get secondaryBackgroundColor => const Color(0xff1F2024);

  @override
  Color get surfaceDarkCard => const Color(0xFF2F3036);
  @override
  Color get surfaceDark => const Color(0xFF1F2024);
  @override
  Color get surface => const Color(0xFF1F2024);

  @override
  Color get cardBackground => const Color(0xFF2F3036);
  @override
  Color get lectureThumbnailBackground => const Color(0xFFFFD4D4);
  @override
  Color get whiteBackground => const Color(0xFF2F3036);

  @override
  Color get normalTextColor => const Color(0xffF8F9FE);
  @override
  Color get textDark => const Color(0xffF8F9FE);
  @override
  Color get textLightColor => const Color(0xFF9E9E9E);
  @override
  Color get textDarkColor => const Color(0xffF8F9FE);
  @override
  Color get secondaryTextColor => const Color(0xFF9E9E9E);

  @override
  Color get hintTextColor => const Color(0xFF6B7280);
  @override
  Color get textWhite => Colors.white;
  @override
  Color get textGrey => const Color(0xFF9E9E9E);

  @override
  Color get grey => const Color(0xFF6B7280);
  @override
  Color get greyLight => const Color(0xFF9E9E9E);

  @override
  Color get borderColor => const Color(0xFF121212);
  @override
  Color get dividerColor => const Color(0xff2F3036);
  @override
  Color get textFieldBorder => const Color(0xFF2F3036);

  @override
  Color get textFormColor => const Color(0xFF6B7280);
  @override
  Color get disabledTextField => const Color(0xFF3A3B3F);
  @override
  Color get textFieldIconColor => const Color(0xFF9CA3AF);

  @override
  Color get errorRed => const Color(0xFFFF5630);
  @override
  Color get logoutRed => const Color(0xFFDF0000);
  @override
  Color get successGreen => const Color(0xff36B37E);
  @override
  Color get warningToast => const Color(0xFFFFAB00);
  @override
  Color get redMoneyColor => const Color(0xFFEF4444);
  @override
  Color get leafGreen => const Color(0xff36B37E);
  @override
  Color get orange => Colors.orange;
  @override
  Color get red => Colors.red;
  @override
  Color get deepRed => const Color(0xFFB71C1C);

  @override
  Color get shimmerBaseColor => Colors.grey.shade700;
  @override
  Color get shimmerHighlightColor => Colors.grey.shade500;
  @override
  Color get shimmerDark => Colors.grey.shade300;
  @override
  Color get shimmerMid => Colors.grey.shade200;
  @override
  Color get shimmerLight => Colors.grey.shade100;
  @override
  Color get shimmerOnlyForBase => Colors.grey.shade50;

  @override
  Color get buttonSoftSplash => const Color(0x1A000000);
  @override
  Color get buttonSoftColor => const Color(0xFF3A3B3F);
  @override
  Color get buttonSplash => const Color(0x1AFFFFFF);

  @override
  Color get overlayDark => const Color(0x80000000);
  @override
  Color get overlayLight => const Color(0x80FFFFFF);

  @override
  Color get bannerColor => const Color(0xff280000);
  @override
  Color get cardIcon => const Color.fromRGBO(255, 180, 180, 1);
}

class _LightColors implements AppColorsTheme {
  @override
  Color get primaryColor => const Color(0xffB00C22);
  @override
  Color get primaryDark => const Color(0xff8A0A1B);
  @override
  Color get buttonColor => primaryColor;

  @override
  Color get white => Colors.white;
  @override
  Color get white70 => Colors.white70;
  @override
  Color get black => Colors.black;
  @override
  Color get transparent => Colors.transparent;

  @override
  Color get scaffoldBackgroundColor => const Color(0xFFF3F4F6);
  @override
  Color get backgroundColor => const Color(0xFFFFF7F7);
  @override
  Color get secondaryBackgroundColor => const Color(0xFFFFFFFF);

  @override
  Color get surfaceDarkCard => const Color(0xFFFFFFFF);
  @override
  Color get surfaceDark => const Color(0xFFF8FAFC);
  @override
  Color get surface => const Color(0xFFFFFFFF);

  @override
  Color get cardBackground => const Color(0xFFFFFFFF);
  @override
  Color get lectureThumbnailBackground => const Color(0xFFFFE5E5);
  @override
  Color get whiteBackground => const Color(0xFFFFFFFF);

  @override
  Color get normalTextColor => const Color(0xFF0F172A);
  @override
  Color get textDark => const Color(0xFF1E293B);
  @override
  Color get textLightColor => const Color(0xFF64748B);
  @override
  Color get textDarkColor => const Color(0xFF334155);
  @override
  Color get secondaryTextColor => const Color(0xFF475569);

  @override
  Color get hintTextColor => const Color(0xFF94A3B8);
  @override
  Color get textWhite => Colors.white;
  @override
  Color get textGrey => const Color(0xFF64748B);

  @override
  Color get grey => const Color(0xFF64748B);
  @override
  Color get greyLight => const Color(0xFF94A3B8);

  @override
  Color get borderColor => const Color(0xFFE2E8F0);
  @override
  Color get dividerColor => const Color(0xFFE2E8F0);
  @override
  Color get textFieldBorder => const Color(0xFFE2E8F0);

  @override
  Color get textFormColor => const Color(0xFF475569);
  @override
  Color get disabledTextField => const Color(0xFFF1F5F9);
  @override
  Color get textFieldIconColor => const Color(0xFF94A3B8);

  @override
  Color get errorRed => const Color(0xFFFF3B30);
  @override
  Color get logoutRed => const Color(0xFFE53935);
  @override
  Color get successGreen => const Color(0xff34C759);
  @override
  Color get warningToast => const Color(0xFFFF9500);
  @override
  Color get redMoneyColor => const Color(0xFFEF4444);
  @override
  Color get leafGreen => const Color(0xff34C759);
  @override
  Color get orange => Colors.orange;
  @override
  Color get red => Colors.red;
  @override
  Color get deepRed => const Color(0xFFB71C1C);

  @override
  Color get shimmerBaseColor => Colors.grey.shade300;
  @override
  Color get shimmerHighlightColor => Colors.grey.shade100;
  @override
  Color get shimmerDark => Colors.grey.shade400;
  @override
  Color get shimmerMid => Colors.grey.shade300;
  @override
  Color get shimmerLight => Colors.grey.shade200;
  @override
  Color get shimmerOnlyForBase => Colors.grey.shade100;

  @override
  Color get buttonSoftSplash => const Color(0x1A000000);
  @override
  Color get buttonSoftColor => const Color(0xFFE2E8F0);
  @override
  Color get buttonSplash => const Color(0x1AFFFFFF);

  @override
  Color get overlayDark => const Color(0x40000000);
  @override
  Color get overlayLight => const Color(0x80FFFFFF);

  @override
  Color get bannerColor => const Color(0xffFFF0F0);
  @override
  Color get cardIcon => const Color(0xFFFFB4B4);
}
