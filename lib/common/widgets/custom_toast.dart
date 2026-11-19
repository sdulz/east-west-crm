import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/key_constant.dart';
import 'package:field_crm/common/constant/style_constant.dart';

enum ToastType { success, error, warning }

void showCustomSuccessToast(String value) {
  showCustomToast(value, ToastType.success);
}

void showCustomWarningToast(String value) {
  showCustomToast(value, ToastType.warning);
}

void showCustomErrorToast(String value) {
  showCustomToast(value, ToastType.error);
}

void showCustomToast(String text, ToastType type) async {
  final context = CommonConstants.navKey.currentContext;
  if (context == null) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 5),
      elevation: 0,
      showCloseIcon: false,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      backgroundColor: ColorConstant.transparent,
      content: getCustomSnackBar(text, type),
    ),
  );
}

Widget getCustomSnackBar(String text, ToastType type) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 15.h),
    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
    decoration: BoxDecoration(
      boxShadow: const [
        BoxShadow(
          offset: Offset(0, 10),
          blurRadius: 10,
          spreadRadius: -5,
          color: Color.fromRGBO(0, 0, 0, 0.04),
        ),
        BoxShadow(
          offset: Offset(0, 20),
          blurRadius: 25,
          spreadRadius: -5,
          color: Color.fromRGBO(0, 0, 0, 0.02),
        ),
      ],
      color: _getColor(type),
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_getIcon(type), color: Colors.white),
            SizedBox(width: 16.w),
            Expanded(child: Text(text, style: _getStyle(type))),
            IconButton.filled(
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: ColorConstant.transparent,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                final context = CommonConstants.navKey.currentContext;
                if (context == null) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.removeCurrentSnackBar();
              },
              icon: Icon(Icons.close_rounded, size: 20.r, color: Colors.white),
            ),
          ],
        ),
      ],
    ),
  );
}

Color _getColor(ToastType type) {
  return switch (type) {
    ToastType.success => ColorConstant.leafGreen,
    ToastType.error => const Color(0xFFE53935),
    ToastType.warning => const Color(0xFFFFA726), 
  };
}

IconData _getIcon(ToastType type) {
  return switch (type) {
    ToastType.success => Icons.info_outline_rounded,
    ToastType.warning => Icons.warning_amber_rounded,
    ToastType.error => Icons.cancel_outlined,
  };
}

TextStyle _getStyle(ToastType type) {
  return switch (type) {
    ToastType.error => StylesConstants.normal14w700.copyWith(
      color: Colors.white,
    ),
    _ => StylesConstants.normal14w500.copyWith(color: Colors.white),
  };
}
