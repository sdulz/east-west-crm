import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/style_constant.dart';
import 'package:field_crm/common/utils/icon_style.dart';

class CustomDecoration {
  static TextStyle errorStyle = StylesConstants.fontRed12w500;

  static TextStyle get hintStyle => StylesConstants.hintGrey14w400;

  static InputDecoration getDecoration({
    required String hintText,
    bool hasMultipleLines = false,
    Widget? prefixWidget,
    Widget? suffixWidget,
    VoidCallback? onClear,
    IconData? passwordIcon,
    VoidCallback? onPasswordToggle,
    double? borderRadius,
    Color? fillColor, 
    Color? borderColor,
    TextStyle? hintStyle,
    bool haveCustomSuffix = false,
    String? maxLengthCounter,
  }) {
    final radiusValue = BorderRadius.circular(borderRadius ?? 14.r);

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: radiusValue,
      borderSide: BorderSide(color: color, width: 2),
    );

    return InputDecoration(
      counterText: maxLengthCounter,
      counterStyle: StylesConstants.primary10w600,

      contentPadding: EdgeInsets.symmetric(
        vertical: hasMultipleLines ? 20.h : 14.h,
        horizontal: 16.w,
      ),
      enabledBorder: border(borderColor ?? ColorConstant.textFieldBorder),
      focusedBorder: border(ColorConstant.red),
      errorBorder: border(ColorConstant.red),
      focusedErrorBorder: border(ColorConstant.red),
      disabledBorder: border(ColorConstant.disabledTextField),

      filled: true,
      fillColor: ColorConstant.secondaryBackgroundColor, 
      hintText: hintText,
      hintStyle: hintStyle ?? CustomDecoration.hintStyle,

      errorMaxLines: 5,
      errorStyle: errorStyle,

      prefixIcon:
          prefixWidget != null
              ? Padding(
                padding: EdgeInsets.only(left: 12.w, right: 8.w),
                child: prefixWidget,
              )
              : null,

      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

      suffixIcon: _getSuffixIcon(
        suffixWidget,
        passwordIcon,
        onPasswordToggle,
        onClear,
      ),
    );
  }

  static Widget? _getSuffixIcon(
    Widget? suffixWidget,
    IconData? passwordIcon,
    VoidCallback? onClickSuffixToggle,
    VoidCallback? onClear,
  ) {
    Widget? baseSuffix;

    if (passwordIcon != null) {
      baseSuffix = IconButton(
        onPressed: onClickSuffixToggle,
        icon: Icon(passwordIcon, color: ColorConstant.textFieldIconColor),
        splashColor: ColorConstant.transparent,
        highlightColor: ColorConstant.transparent,
      );
    } else {
      baseSuffix = suffixWidget;
    }

    if (onClear != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            style: iconStyleFrom,
            onPressed: onClear,
            icon: Icon(
              Icons.close,
              size: 20.sp,
              color: ColorConstant.textFieldIconColor,
            ),
          ),
          SizedBox(width: 4.w),
          if (baseSuffix != null)
            Transform.translate(offset: Offset(-10.w, 0), child: baseSuffix),
        ],
      );
    }

    return baseSuffix;
  }
}
