import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/style_constant.dart';

class GenericFilterDropdown<T> extends ConsumerStatefulWidget {
  final String hint;
  final String Function(T) headingMapper;
  final List<T> items;
  final ValueNotifier<T?> selectedValueController;
  final void Function(T?)? onChanged;
  final bool disabled;
  final IconData? icon;
  final Color? buttonColor;
  final Color? textColor;
  final Color? sheetColor;

  const GenericFilterDropdown({
    super.key,
    required this.hint,
    required this.headingMapper,
    required this.items,
    required this.selectedValueController,
    this.onChanged,
    this.disabled = false,
    this.icon,
    this.buttonColor,
    this.textColor,
    this.sheetColor,
  });

  @override
  ConsumerState<GenericFilterDropdown<T>> createState() =>
      _GenericFilterDropdownState<T>();
}

class _GenericFilterDropdownState<T>
    extends ConsumerState<GenericFilterDropdown<T>> {
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
    widget.selectedValueController.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    widget.selectedValueController.removeListener(_onValueChanged);
    super.dispose();
  }

  void _onValueChanged() {
    _updateSelectedIndex();
    setState(() {});
  }

  void _updateSelectedIndex() {
    final value = widget.selectedValueController.value;
    if (value != null) {
      final index = widget.items.indexWhere((e) => e == value);
      if (index != -1) {
        selectedIndex = index;
      }
    }
  }

  void _showFilterSheet() async {
    if (widget.disabled) return;

    FocusScope.of(context).unfocus();

    final newIndex = await showModalBottomSheet<int>(
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorConstant.transparent,
      builder:
          (context) => _CompactFilterSheet<T>(
            selectedIndex: selectedIndex,
            items: widget.items,
            headingMapper: widget.headingMapper,
            sheetColor: widget.sheetColor,
          ),
    );

    if (newIndex != null && newIndex != selectedIndex) {
      selectedIndex = newIndex;
      final newValue = widget.items.elementAtOrNull(newIndex);
      widget.selectedValueController.value = newValue;
      widget.onChanged?.call(newValue);
      setState(() {});
    }
  }

  String get _displayText {
    final value = widget.selectedValueController.value;
    if (value != null) {
      return widget.headingMapper(value);
    }
    return widget.hint;
  }

  @override
  Widget build(BuildContext context) {
    final defaultButtonColor =
        widget.buttonColor ?? ColorConstant.borderColor;

    final defaultTextColor = widget.textColor ?? ColorConstant.normalTextColor;

    return GestureDetector(
      onTap: widget.disabled ? null : _showFilterSheet,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color:
              widget.disabled
                  ? defaultButtonColor.withValues(alpha: 0.5)
                  : defaultButtonColor,
          borderRadius: BorderRadius.circular(30.r),
          border: Theme.of(context).brightness == Brightness.dark
              ? null
              : Border.all(
                  color: ColorConstant.borderColor.withValues(alpha: 0.15),
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon ?? Icons.tune,
              color:
                  widget.disabled
                      ? defaultTextColor.withValues(alpha: 0.4)
                      : defaultTextColor.withValues(alpha: 0.8),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              _displayText,
              style: StylesConstants.normal14w500.copyWith(
                color:
                    widget.disabled
                        ? defaultTextColor.withValues(alpha: 0.4)
                        : defaultTextColor,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down,
              color:
                  widget.disabled
                      ? defaultTextColor.withValues(alpha: 0.3)
                      : defaultTextColor.withValues(alpha: 0.6),
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact bottom sheet
class _CompactFilterSheet<T> extends StatelessWidget {
  final int? selectedIndex;
  final List<T> items;
  final String Function(T) headingMapper;
  final Color? sheetColor;

  const _CompactFilterSheet({
    required this.selectedIndex,
    required this.items,
    required this.headingMapper,
    this.sheetColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultSheetColor = ColorConstant.surfaceDark;

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: defaultSheetColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorConstant.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Options
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return InkWell(
                onTap: () => Navigator.pop(context, index),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 14.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        headingMapper(item),
                        style: StylesConstants.normal14w500.copyWith(
                          color:
                              isSelected
                                  ? ColorConstant.primaryColor
                                  : ColorConstant.normalTextColor.withValues(alpha: 
                                    0.85,
                                  ),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: ColorConstant.primaryColor,
                          size: 20.sp,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
