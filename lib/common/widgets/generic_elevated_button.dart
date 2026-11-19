import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/style_constant.dart';
import 'package:field_crm/common/widgets/loading.dart';

class GenericElevatedButton extends StatelessWidget {
  static TextStyle get buttonTextStyle => StylesConstants.fontWhite12w600;
  final String title;
  final bool loading;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final double? height;
  final double? width;
  final TextStyle? textStyle;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final EdgeInsets? padding;
  final Widget? extraSuffix;
  final bool isPadding;
  final BorderSide? borderSide;

  ///Replaces title
  final Widget? child;

  final Widget? prefix;

  factory GenericElevatedButton.secondary({
    required String title,
    required VoidCallback onPressed,
    Widget? prefix,
    bool isPadding = true,
  }) {
    return GenericElevatedButton(
      splashColor: ColorConstant.buttonSoftSplash,
      backgroundColor: ColorConstant.buttonSoftColor,
      prefix: prefix,
      textStyle: GenericElevatedButton.buttonTextStyle.copyWith(
        color: ColorConstant.buttonColor,
      ),
      onPressed: onPressed,
      title: title,
      isPadding: isPadding,
    );
  }

  const GenericElevatedButton({
    super.key,
    required this.title,
    this.prefix,
    this.borderSide,
    this.isDisabled = false,
    this.onPressed,
    this.height,
    this.width,
    this.textStyle,
    this.loading = false,
    this.child,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.splashColor,
    this.padding,
    this.extraSuffix,
    this.isPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = this.prefix;
    return Container(
      height: height ?? 46.h,
      width: width ?? MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(bottom: !isPadding ? 0 : 12.h),
      child: Semantics(
        label: title,
        child: ElevatedButton(
          style: buildButtonStyle(
            context,
            isDisabled: isDisabled,
            elevation: elevation,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            splashColor: splashColor,
            padding: padding,
            side: borderSide,
          ),
          onPressed: (isDisabled || loading) ? null : onPressed,
          child: DefaultTextStyle(
            style: textStyle ??
                (backgroundColor == null || backgroundColor == ColorConstant.buttonColor || backgroundColor == ColorConstant.primaryColor
                    ? buttonTextStyle.copyWith(color: ColorConstant.white)
                    : buttonTextStyle),
            child:
                loading
                    ?  Center(
                      child: CustomLoadingIndicator(
                        scale: 0.85,
                        color: ColorConstant.white,
                      ),
                    )
                    : child ??
                        Text.rich(
                          TextSpan(
                            children: [
                              if (prefix != null)
                                WidgetSpan(
                                  child: prefix,
                                  alignment: PlaceholderAlignment.middle,
                                ),
                              TextSpan(text: title),
                              if (extraSuffix != null)
                                WidgetSpan(
                                  child: extraSuffix ?? const SizedBox(),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
          ),
        ),
      ),
    );
  }

  static ButtonStyle buildButtonStyle(
    BuildContext context, {
    double? elevation,
    bool isDisabled = false,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Color? splashColor,
    EdgeInsets? padding,
    BorderSide? side,
  }) {
    final buttonColor = ColorConstant.buttonColor;
    return ButtonStyle(
      side:
          side == null
              ? null
              : WidgetStateProperty.resolveWith<BorderSide>((
                Set<WidgetState> states,
              ) {
                return side;
              }),
      padding:
          padding == null
              ? null
              : WidgetStateProperty.resolveWith<EdgeInsetsGeometry>((
                Set<WidgetState> states,
              ) {
                return padding;
              }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.pressed)
            ? splashColor ?? ColorConstant.buttonSplash
            : null;
      }),
      elevation: WidgetStateProperty.all(elevation ?? 0),
      backgroundColor: WidgetStateProperty.all(
        isDisabled
            ? Theme.of(context).disabledColor
            : backgroundColor ?? buttonColor,
      ),
      splashFactory: InkRipple.splashFactory,
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(40.r),
        ),
      ),
    );
  }
}
