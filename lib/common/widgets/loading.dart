import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double scale;
  final Color? color;

  const CustomLoadingIndicator({this.scale = 1, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return SpinKitFadingCircle(
      color: color ?? ColorConstant.primaryColor,
      size: 30.r * scale,
      duration: const Duration(milliseconds: 1000),
    );
  }
}
