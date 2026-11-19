import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/style_constant.dart';

class DetailsRow extends StatelessWidget {
  final String heading;
  final String? value;
  final Widget? child;
  final bool light;

  const DetailsRow({
    super.key,
    required this.heading,
    required this.value,
  })  : child = null,
        light = false;

  const DetailsRow.light({
    super.key,
    required this.heading,
    required this.value,
  })  : child = null,
        light = true;

  const DetailsRow.fromChild({
    super.key,
    required this.heading,
    required this.child,
  })  : value = null,
        light = false;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value == null && child == null) return const SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Expanded(
          flex: 2,
          child: Text(
            heading,
            style: StylesConstants.grey14w400, 
          ),
        ),

        SizedBox(width: 5.w),

    
        Expanded(
          flex: 3,
          child: child != null
              ? Align(
                  alignment: Alignment.centerRight,
                  child: child,
                )
              : Text(
                  value ?? "",
                  style: light
                      ? StylesConstants.normal14w500
                      : StylesConstants.normal14w600,
                  textAlign: TextAlign.end,
                ),
        ),
      ],
    );
  }
}

class DetailsColumn extends StatelessWidget {
  final String heading;
  final String? value;
  final bool? isLeftAlign;
  final bool isPhoneNumber;

  const DetailsColumn({
    super.key,
    required this.heading,
    required this.value,
    this.isLeftAlign = true,
    this.isPhoneNumber = false,
  });

  const DetailsColumn.right({
    super.key,
    required this.heading,
    required this.value,
    this.isPhoneNumber = false,
  }) : isLeftAlign = false;

  const DetailsColumn.center({
    super.key,
    required this.heading,
    required this.value,
    this.isPhoneNumber = false,
  }) : isLeftAlign = null;

  @override
  Widget build(BuildContext context) {
    var value = this.value;
    if (value == null || value.isEmpty) {
      value = "-";
    }

    final align = _align();

    return Column(
      crossAxisAlignment: _crossAlignment(),
      children: [

        Text(
          heading,
          style: StylesConstants.grey14w400, 
          textAlign: align,
        ),

        SizedBox(height: 5.h),

        isPhoneNumber && value != "-"
            ? Row(
                mainAxisAlignment: (isLeftAlign ?? true)
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: StylesConstants.normal14w600,
                    textAlign: align,
                  ),
                ],
              )
            : Text(
                value,
                style: StylesConstants.normal14w600,
                textAlign: align,
              ),
      ],
    );
  }

  TextAlign _align() {
    return switch (isLeftAlign) {
      true => TextAlign.left,
      false => TextAlign.right,
      null => TextAlign.center,
    };
  }

  CrossAxisAlignment _crossAlignment() {
    return switch (isLeftAlign) {
      true => CrossAxisAlignment.start,
      false => CrossAxisAlignment.end,
      null => CrossAxisAlignment.center,
    };
  }
}
