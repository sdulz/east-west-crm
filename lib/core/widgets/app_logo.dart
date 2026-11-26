import 'package:field_crm/common/constant/image_constant.dart';
import 'package:flutter/material.dart';

/// East West Enterprises brand logo, framed cleanly for both light & dark themes.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size * 0.62,
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.08,
        vertical: size * 0.06,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.14),
        border: isDark
            ? Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        ImageConstants.appLogo,
        fit: BoxFit.contain,
      ),
    );
  }
}
