import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/image_constant.dart';
import 'package:field_crm/common/constant/style_constant.dart';

class EmptyDataWidget extends StatelessWidget {
  final String message;
  final String image;

  const EmptyDataWidget({
    super.key,
    this.message = "No Data Found",
    this.image = ImageConstants.emptyData,
  });

  @override
  Widget build(BuildContext context) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    String finalImage = image;
    
    if (isLight) {
      if (image == ImageConstants.emptyData) {
        finalImage = ImageConstants.emptyDataWhite;
      } else if (image == ImageConstants.emptyLiveClass) {
        finalImage = ImageConstants.emptyLiveClassWhite;
      } else if (image == ImageConstants.exceptionImage) {
        finalImage = ImageConstants.exceptionImageWhite;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(finalImage, height: 150.h, width: 150.w),
        SizedBox(height: 16.h),
        Text(message, style: StylesConstants.grey14w400),
      ],
    );
  }
}
