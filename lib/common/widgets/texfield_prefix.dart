import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/widgets/custom_decoration.dart';


import 'generic_textfield.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class TextFieldPrefixText extends StatelessWidget {
  final String text;
  final bool showBorder;
  final TextStyle? style;
  final VoidCallback? onTap;

  const TextFieldPrefixText({
    super.key,
    required this.text,
    this.onTap,
    this.showBorder = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = PrefixInheritedWidget.inheritedHighlight(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 14.w),
          Text(
            text,
            style: style ??
                (highlight
                    ? GenericTextField.usedStyle
                    : CustomDecoration.hintStyle),
          ),
          if (showBorder) ...[
            SizedBox(width: 10.w),
            Container(
              color: ColorConstant.red, //Todo: Refactor
              width: 1,
              height: 26.h,
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}

class PrefixInheritedWidget extends InheritedWidget {
  const PrefixInheritedWidget({
    super.key,
    required this.highlight,
    required super.child,
  });

  final bool highlight;

  static bool inheritedHighlight(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<PrefixInheritedWidget>();
    return result?.highlight ?? false;
  }

  @override
  bool updateShouldNotify(PrefixInheritedWidget oldWidget) =>
      highlight != oldWidget.highlight;
}
