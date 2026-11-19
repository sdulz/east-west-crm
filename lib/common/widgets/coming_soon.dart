import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/style_constant.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.borderColor,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon or Illustration
              Icon(
                Icons.construction_rounded,
                size: 80.sp,
                color: ColorConstant.textLightColor,
              ),
              SizedBox(height: 24.h),

              // Title
              Text(
                "$title coming soon!",
                textAlign: TextAlign.center,
                style: StylesConstants.fontWhite22w700.copyWith(
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12.h),

              // Subtitle
              Text(
                "We're working hard to bring you the best experience. Stay tuned!",
                textAlign: TextAlign.center,
                style: StylesConstants.grey14w400.copyWith(
                  color: ColorConstant.textLightColor,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 40.h),

              // Optional: Back Button or Home Button
              OutlinedButton(
                onPressed: () => Navigator.maybePop(context),
                style: OutlinedButton.styleFrom(
                  side:  BorderSide(color: ColorConstant.textLightColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  "Go Back",
                  style: StylesConstants.fontWhite70_14w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
