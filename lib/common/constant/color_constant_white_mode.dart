import 'package:flutter/material.dart';

class ColorConstantLight {
  ColorConstantLight._();

  // ───────── PRIMARY BRAND COLORS ─────────
  static const Color primaryColor = Color(0xffB00C22);
  static const Color primaryDark = Color(0xff8A0A1B);
  static const Color buttonColor = primaryColor;

  // ───────── NEUTRALS / BASICS ─────────
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ───────── BACKGROUND COLORS ─────────
  static const Color scaffoldBackgroundColor = Color(0xFFF3F4F6);
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color secondaryBackgroundColor = Color(0xffF4F4F4);
  static const Color surfaceDark = Color(0xFFECECEC);
  static const Color surface = Colors.white;

  // ───────── TEXT COLORS ─────────
  static const Color normalTextColor = Color(0xFF141414);
  static const Color textGrey = Color(0xFF5C5C5C);
  static const Color textDark = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFF9E9E9E);

  // ───────── BORDER / DIVIDER COLORS ─────────
  static const Color borderColor = Color(0xFFF9FAFB);
  static const Color textFieldBorder = Color(0xFFD1D5DB);

  // ───────── INPUT FIELD COLORS ─────────
  static const Color textFormColor = Color(0xFF141414);
  static const Color disabledTextField = Color(0xFFF3F4F6);
  static const Color textFieldIconColor = Color(0xFF6B7280);

  // ───────── STATUS COLORS ─────────
  static const Color errorRed = Color(0xFFFF5630);
  static const Color logoutRed = Color(0xFFDF0000);
  static const Color successGreen = Color(0xff36B37E);
  static const Color warningToast = Color(0xFFFFAB00);
  static const Color redMoneyColor = Color(0xFFEF4444);
  static const Color leafGreen = Color(0xFF36B37E);
  static const Color orange = Colors.orange;
  static const Color red = Colors.red;

  // ───────── SHIMMER / LOADING COLORS ─────────
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);
  static final Color shimmerDark = Colors.grey.shade400;
  static final Color shimmerMid = Colors.grey.shade300;
  static final Color shimmerLight = Colors.grey.shade200;
  static final Color shimmerOnlyForBase = Colors.grey.shade100;

  // ───────── BUTTON STATES / OVERLAYS ─────────
  static const Color buttonSoftSplash = Color(0x1A000000);
  static const Color buttonSoftColor = Color(0xFFF3F4F6);
  static const Color buttonSplash = Color(0x1A000000);

  // ───────── TRANSPARENCY / OVERLAYS ─────────
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x80FFFFFF);

  // ───────── OTHERS ─────────
  static const Color bannerColor = Color(0xFFFFEAEA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardIcon = Color(0xFFB00C22);
}

extension ColorHelper on Color {
  Color withCustomOpacity(double opacity) => withValues(alpha: opacity);
}
