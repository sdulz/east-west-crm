import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/style_constant.dart';
import 'package:field_crm/common/widgets/custom_decoration.dart';
import 'package:field_crm/common/widgets/texfield_prefix.dart';

class GenericTextField extends StatefulWidget {
  static TextStyle get usedStyle => StylesConstants.normal14w400;
  final String hintText;
  final bool isDisabled;
  final VoidCallback? onClear;

  final Widget? prefixWidget;

  /// This value is ignored if the TextField is password
  final Widget? suffixWidget;
  final bool isPassword;
  final VoidCallback? onTap;
  final TextInputType keywordType;
  final String? Function(String?)? validate;
  final Function(String)? onFieldSubmit;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextNode;
  final Function? onSave;
  final void Function(String?)? onChanged;
  final TextEditingController? controller;
  final bool readonly;
  final int? maxLength;
  final int? maxLines;
  final TextCapitalization textCapitalization;

  final double? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final Iterable<String>? autoFillHints;

  final bool autofocus;
  final bool centerText;
  final String? initialValue;
  final List<TextInputFormatter>? formatterList;
  final String? heading;
  final Widget? headingWidgetSpan;
  final Widget? headingSuffix;
  final Widget? customSuffix;
  final ValueNotifier<bool>? invalidCorrectionController;
  final bool showMax;

  ///Uses [usedStyle] is not passed
  final TextStyle? style;
  final TextStyle? hintStyle;

  ///Shows red *
  final bool showRequired;

  const GenericTextField({
    super.key,
    required this.invalidCorrectionController,
    this.heading,
    this.headingWidgetSpan,
    this.headingSuffix,
    this.style,
    this.hintStyle,
    this.textCapitalization = TextCapitalization.words,
    required this.hintText,
    required this.textInputAction,
    required this.validate,
    this.showRequired = true,
    this.customSuffix,
    this.formatterList,
    this.maxLines,
    this.borderRadius,
    this.prefixWidget,
    this.suffixWidget,
    this.isPassword = false,
    this.keywordType = TextInputType.text,
    this.onFieldSubmit,
    this.readonly = false,
    this.focusNode,
    this.onSave,
    this.controller,
    this.onChanged,
    this.autofocus = false,
    this.maxLength,
    this.fillColor,
    this.borderColor,
    this.onTap,
    this.centerText = false,
    this.autoFillHints,
    this.isDisabled = false,
    this.initialValue,
    this.nextNode,
    this.onClear,
    this.showMax = false,
  });

  @override
  State<GenericTextField> createState() => _GenericTextFieldState();
}

class _GenericTextFieldState extends State<GenericTextField> {
  String maxLimitError = "";
  var hidePassword = true;

  @override
  void initState() {
    super.initState();
    widget.invalidCorrectionController?.addListener(_invalidCorrectionListener);
  }

  void _invalidCorrectionListener() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.invalidCorrectionController?.removeListener(
      _invalidCorrectionListener,
    );
    super.dispose();
  }

  void _validateInput(String text) {
    if (!widget.showMax) return;
    final maxLength = widget.maxLength;

    if (maxLength == null) return;
    if (text.length == maxLength) {
      setState(() {
        maxLimitError = 'Max ${widget.maxLength}';
      });
    } else {
      if (maxLimitError.isEmpty) return;
      setState(() {
        maxLimitError = "";
      });
    }
  }

  late bool _haveValue = widget.controller?.text.isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final heading = widget.heading;
    final textField = Focus(
      onFocusChange: (isSelected) {
        // _isSelected = isSelected;
        // setState(() {});
      },
      child: PrefixInheritedWidget(
        highlight: _haveValue,
        child: TextFormField(
          autovalidateMode:
              widget.invalidCorrectionController?.value == true
                  ? AutovalidateMode.onUserInteraction
                  : null,
          contextMenuBuilder: (context, editableTextState) {
            return Theme(
              data: ThemeData(),
              child: AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: editableTextState.contextMenuButtonItems,
              ),
            );
          },
          style: widget.style ?? GenericTextField.usedStyle,
          initialValue: widget.initialValue,
          maxLines: widget.maxLines ?? 1,
          maxLength: widget.maxLength,
          enabled: !widget.isDisabled,
          textAlign: widget.centerText ? TextAlign.center : TextAlign.start,
          autofocus: widget.autofocus,
          onChanged: (newValue) {
            // if (widget.keywordType != TextInputType.emailAddress) {
            //   String capitalized = newValue
            //       .split(' ')
            //       .map((word) => word.isNotEmpty
            //           ? '${word[0].toUpperCase()}${word.substring(1)}'
            //           : '')
            //       .join(' ');
            //   if (widget.controller?.value != null) {
            //     widget.controller?.value = widget.controller!.value.copyWith(
            //       text: capitalized,
            //       selection: TextSelection.fromPosition(
            //         TextPosition(offset: capitalized.length),
            //       ),
            //     );
            //   }
            // }

            if (widget.prefixWidget != null) {
              _haveValue = newValue.isNotEmpty;
              setState(() {});
            }
            _validateInput(newValue);
            widget.onChanged?.call(newValue);
          },
          controller: widget.controller,
          onSaved: (newValue) {
            if (widget.onSave != null) widget.onSave!(newValue);
          },
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: (newValue) {
            if (widget.onFieldSubmit != null) widget.onFieldSubmit!(newValue);
            FocusScope.of(context).requestFocus(widget.nextNode);
          },
          validator: widget.validate,
          keyboardType: widget.keywordType,
          textCapitalization: widget.textCapitalization,
          readOnly: widget.readonly,
          onTap: widget.onTap,
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          autofillHints: widget.autoFillHints,
          inputFormatters: widget.formatterList,
          obscureText: widget.isPassword && hidePassword,
          decoration: CustomDecoration.getDecoration(
            hasMultipleLines: widget.maxLines != null && widget.maxLines! > 1,
            onClear: widget.onClear,
            hintText: widget.hintText,
            haveCustomSuffix: widget.customSuffix != null,
            passwordIcon:
                widget.isPassword
                    ? hidePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded
                    : null,
            prefixWidget:
                widget.prefixWidget != null
                    ? Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: widget.prefixWidget,
                    )
                    : null,
            suffixWidget: widget.suffixWidget,
            onPasswordToggle: () {
              if (widget.isPassword) {
                setState(() {
                  hidePassword = !hidePassword;
                });
              }
            },
            borderRadius: widget.borderRadius,
            //Todo: refactor this logic, its too complicated
            fillColor:
                widget.fillColor ??
                (widget.isDisabled
                    ? ColorConstant.disabledTextField
                    : ColorConstant.white),
            borderColor: widget.borderColor,
            maxLengthCounter: maxLimitError,
            hintStyle: widget.hintStyle,
          ),
        ),
      ),
    );

    Widget withCustomSuffix; //Todo: Might not be the best way to do it
    final customSuffix = widget.customSuffix;
    if (customSuffix == null) {
      withCustomSuffix = textField;
    } else {
      withCustomSuffix = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: textField),
          SizedBox(
            height: 48,
            //Todo: CRITICAL Can cause trouble. If i use IntrinsicHeight on error its causing trouble, may manually calculate
            child: Transform.translate(
              offset: const Offset(-1.25, 0),
              child: customSuffix,
            ),
          ),
        ],
      );
    }
    if (heading == null) return withCustomSuffix;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFieldHeader(
          isRequired: widget.showRequired,
          heading: heading,
          headingSuffix: widget.headingSuffix,
        ),
        withCustomSuffix,
      ],
    );
  }
}

class TextFieldHeader extends StatelessWidget {
  const TextFieldHeader({
    super.key,
    required this.heading,
    required this.headingSuffix,
    required this.isRequired,
    this.highlight = false,
  });

  final String heading;
  final Widget? headingSuffix;
  final bool isRequired;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: heading,
                    style:
                        highlight
                            ? StylesConstants.normal14w600
                            : StylesConstants.normal14w500,
                  ),
                  if (isRequired)
                    TextSpan(text: " *", style: StylesConstants.fontRed14w500),
                ],
              ),
            ),
          ),
          if (headingSuffix != null) ...[
            SizedBox(width: 5.w),
            headingSuffix ?? const SizedBox(),
          ],
        ],
      ),
    );
  }
}
