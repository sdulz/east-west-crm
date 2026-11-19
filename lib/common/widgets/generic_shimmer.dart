import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:shimmer/shimmer.dart';

class HorizontalScrollingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final int count;

  const HorizontalScrollingShimmer({
    super.key,
    this.width = 200,
    this.height = 233,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    final hPadding = 16.w;
    final spaceSizedBox = SizedBox(width: hPadding);

    final boxForShimmer = SizedBox(height: height.h, width: width.w);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i != 0) spaceSizedBox,
            DarkShimmer(child: boxForShimmer),
          ],
        ],
      ),
    );
  }
}

class ShimmerDecoration extends StatelessWidget {
  final Widget child;

  const ShimmerDecoration({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(color: ColorConstant.shimmerBaseColor, child: child),
    );
  }
}

class DarkShimmer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const DarkShimmer({super.key, required this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12.r),
      child: Shimmer.fromColors(
        baseColor: ColorConstant.shimmerBaseColor,
        highlightColor: ColorConstant.shimmerHighlightColor,
        child: ShimmerDecoration(child: child),
      ),
    );
  }
}
