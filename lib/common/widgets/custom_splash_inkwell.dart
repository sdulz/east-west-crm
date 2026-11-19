
import 'package:flutter/material.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class CustomSplashInkwell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadius radius;
  final Size? size;
  final ShapeBorder? customBorder;

  const CustomSplashInkwell({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    required this.radius,
    this.onLongPress,
    this.size,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: size?.height,
        width: size?.width,
        child: Stack(
          children: [
            if (size == null)
              child
            else
              Positioned.fill(
                child: child,
              ),
            Positioned.fill(
              child: Material(
                color: ColorConstant.transparent,
                child: InkWell(
                  customBorder: customBorder,
                  onLongPress: onLongPress,
                  borderRadius: radius,
                  splashColor: color?.withCustomOpacity(0.25),
                  highlightColor: color?.withCustomOpacity(0.35),
                  onTap: onTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
