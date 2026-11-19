import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

Future<T?> showCustomBottomSheet<T>({
  bool isDismissible = false,
  required Widget title,
  required Widget body,
  required BuildContext context,
  EdgeInsets? contentPadding,
  double? minHeight,
  double? maxHeight,
  Color? backgroundColor,
  ScrollController? scrollController,
}) async {
  return await showModalBottomSheet<T>(
    useSafeArea: true,
    backgroundColor: ColorConstant.transparent,
    barrierColor: ColorConstant.black.withCustomOpacity(0.5),
    constraints: BoxConstraints(
      minHeight: minHeight ?? 200.h,
      maxHeight: maxHeight ?? MediaQuery.of(context).size.height * .9,
    ),
    enableDrag: true,
    isScrollControlled: true,
    isDismissible: isDismissible,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14.95.r)),
    ),
    builder: (_) {
      return _CustomBottomSheet(
        backgroundColor: backgroundColor,
        scrollController: scrollController,
        contentPadding: contentPadding,
        title: title,
        body: body,
        minHeight: minHeight ?? 200.h,
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * .9,
      );
    },
  );
}

class _CustomBottomSheet extends StatelessWidget {
  final double minHeight;
  final double maxHeight;
  final EdgeInsets? contentPadding;
  final Widget title;
  final Widget body;
  final ScrollController? scrollController;
  final Color? backgroundColor;
  const _CustomBottomSheet({
    required this.minHeight,
    required this.maxHeight,
    required this.title,
    required this.body,
    this.contentPadding,
    this.scrollController,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 7.97.w),
      child: Container(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.95.r),
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor ?? ColorConstant.borderColor,
                  ),
                  constraints: const BoxConstraints(),
                  child: CustomBottomSheet(
                    contentPadding: contentPadding,
                    title: title,
                    body: body,
                    scrollController: scrollController,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.98.h),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class CustomBottomSheet extends StatelessWidget {
  final Widget title;
  final Widget body;
  final EdgeInsets? contentPadding;
  final ScrollController? scrollController;
  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.body,
    this.contentPadding,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: contentPadding?.top ?? 13.95.h,
            left: contentPadding?.left ?? 13.95.w,
            right: contentPadding?.right ?? 13.95.w,
            bottom: 0,
          ),
          child: Row(
            children: [
              Expanded(child: title),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.close,
                  color: ColorConstant.textWhite,
                  size: 24.sp,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        SizedBox(height: 11.96.h),
        Flexible(
          child: SingleChildScrollView(
            controller: scrollController,
            child: body,
          ),
        ),
      ],
    );
  }
}
