import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/size_constant.dart';
import 'package:field_crm/common/constant/style_constant.dart';
import 'package:field_crm/common/widgets/generic_textfield.dart';
import 'package:field_crm/common/widgets/no_result_widget.dart';

import 'general_bottom_sheet_header.dart';

class GenericBottomSheetPicker<T> extends StatefulWidget {
  final String sheetTitle;
  final int? selectedIndex;
  final List<T> sheetList;
  final String Function(T) headingMapper;
  final Widget Function(T)? prefixBuilder;
  final Widget Function(T)? widgetMapper;
  final bool closeOnSelected;
  final String searchHintText;
  final bool Function(T)? isGroupHeader;
  final Widget Function(T)? groupHeaderBuilder;

  const GenericBottomSheetPicker({
    super.key,
    required this.sheetTitle,
    required this.selectedIndex,
    required this.headingMapper,
    required this.sheetList,
    this.prefixBuilder,
    this.isGroupHeader,
    this.groupHeaderBuilder,
    this.widgetMapper,

    this.closeOnSelected = true,
    this.searchHintText = "Search",
  });

  @override
  State<GenericBottomSheetPicker<T>> createState() =>
      _GenericBottomSheetPickerState<T>();
}

class _GenericBottomSheetPickerState<T>
    extends State<GenericBottomSheetPicker<T>> {
  late int? selectedIndex = widget.selectedIndex;
  String? searchedValue;
  late List<T> filteredList;

  @override
  void initState() {
    super.initState();
    filteredList = widget.sheetList;
  }

  void _filterList(String? value) {
    setState(() {
      searchedValue = value;
      if (value == null || value.isEmpty) {
        filteredList = widget.sheetList;
      } else {
        filteredList =
            widget.sheetList
                .where(
                  (item) => widget
                      .headingMapper(item)
                      .toLowerCase()
                      .contains(value.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: ColorConstant.surfaceDark,
      child: Padding(
        padding: EdgeInsets.only(
          left: SizeConstants.hPadding,
          right: SizeConstants.hPadding,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),

            GeneralBottomSheetHeader(
              title: widget.sheetTitle,
              onBack: () => Navigator.pop(context, selectedIndex),
            ),

            if (widget.sheetList.length > 5) ...[
              SizedBox(height: 10.h),
              GenericTextField(
                hintText: widget.searchHintText,
                validate: (_) => null,
                onChanged: _filterList,
                textInputAction: TextInputAction.search,
                fillColor: ColorConstant.surfaceDarkCard,

                borderColor: ColorConstant.borderColor,
                borderRadius: 30.r,
                suffixWidget: Icon(
                  Icons.search,
                  color: ColorConstant.textFieldIconColor,
                  size: 20.r,
                ),
                invalidCorrectionController: null,
              ),
              SizedBox(height: 10.h),
            ],

            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height * 0.6),
                child:
                    filteredList.isEmpty
                        ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: const NoResultWidget(),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];

                            if (widget.isGroupHeader?.call(item) ?? false) {
                              return widget.groupHeaderBuilder?.call(item) ??
                                  const SizedBox.shrink();
                            }

                            final originalIndex = widget.sheetList.indexOf(
                              item,
                            );
                            final isSelected = originalIndex == selectedIndex;

                            return Material(
                              color: ColorConstant.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => selectedIndex = originalIndex);
                                  if (widget.closeOnSelected) {
                                    Navigator.pop(context, selectedIndex);
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: Row(
                                    children: [
                                      if (widget.prefixBuilder != null) ...[
                                        widget.prefixBuilder!(item),
                                        SizedBox(width: 10.w),
                                      ],

                                      if (widget.widgetMapper != null)
                                        widget.widgetMapper!(item)
                                      else
                                        Expanded(
                                          child: Text(
                                            widget.headingMapper(item),
                                            style:
                                                isSelected
                                                    ? StylesConstants
                                                        .normal16w600
                                                        .copyWith(
                                                          color:
                                                              ColorConstant
                                                                  .primaryColor,
                                                        )
                                                    : StylesConstants
                                                        .normal16w400
                                                        .copyWith(
                                                          color:
                                                              ColorConstant
                                                                  .normalTextColor,
                                                        ),
                                          ),
                                        ),

                                      Radio<int>(
                                        activeColor: ColorConstant.primaryColor,
                                        visualDensity: VisualDensity.compact,
                                        value: originalIndex,
                                        // ignore: deprecated_member_use
                                        groupValue: selectedIndex,
                                        // ignore: deprecated_member_use
                                        onChanged: (value) {
                                          setState(() => selectedIndex = value);
                                          if (widget.closeOnSelected) {
                                            Navigator.pop(
                                              context,
                                              selectedIndex,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
