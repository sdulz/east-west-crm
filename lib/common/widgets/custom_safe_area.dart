
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:field_crm/common/constant/theme_constant.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class CustomSafeArea extends StatelessWidget {
  final Widget child;

  const CustomSafeArea({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return child;
    }

    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

  
    final systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: ColorConstant.transparent,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDarkMode ? ColorConstant.black : ColorConstant.white,
    );


    final currentTheme = isDarkMode
        ? ThemeConstant.darkTheme(context)
        : ThemeConstant.lightTheme(context);

    return Theme(
      data: currentTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiStyle,
        child: child,
      ),
    );
  }
}
