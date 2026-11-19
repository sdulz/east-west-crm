import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/style_constant.dart';

class GeneralBottomSheetHeader extends StatelessWidget {
  const GeneralBottomSheetHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ColorConstant.borderColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(title, style: StylesConstants.normal18w600)),
              IconButton(
                onPressed:
                    onBack ??
                    () {
                      Navigator.of(context).pop();
                    },
                icon: Icon(Icons.close_rounded, size: 20.r),
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
      ],
    );
  }
}
