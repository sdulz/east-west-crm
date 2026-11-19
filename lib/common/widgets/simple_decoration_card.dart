import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class SimpleDecorationCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? height;
  final double? width;
  final Alignment? alignment;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;
  final BorderRadius? radius;
  final BoxDecoration? decoration;

  const SimpleDecorationCard(
      {super.key,
      required this.child,
      this.padding,
      this.backgroundColor,
      this.height,
      this.width,
      this.alignment,
      this.onPressed,
      this.radius,
      this.decoration});

  @override
  Widget build(BuildContext context) {
    final onPressed = this.onPressed;
    final radius = this.radius ?? BorderRadius.circular(20.r);
    final value = Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: decoration ??
          BoxDecoration(
            color: backgroundColor ?? ColorConstant.white,
            borderRadius: radius,
          ),
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 24.h,
          ),
      child: child,
    );
    if (onPressed == null) return value;

    return GestureDetector(
      onTap: onPressed,
      child: value,
    );
  }
}
