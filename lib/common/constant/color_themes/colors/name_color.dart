import 'package:flutter/material.dart';
import 'package:field_crm/common/constant/color_themes/colors/custom_colors.dart';



class NameTheme extends CustomColors {
  @override
  String get themeName => "Name";

  @override
  Color get primaryLight => const Color(0xFFB00C22); 
  @override
  Color get secondaryLight => const Color(0xFFF1F1F1);

  @override     
  Color get primaryDark => const Color(0xFF8A0A1B);
  @override
  Color get secondaryDark => const Color(0xFF222222);
}
