
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class GenericDateTextFiled extends StatefulWidget {
//   final DateTime? initial;
//   final Function(DateTime)? onChanged;
//   final EdgeInsets? contentPadding;
//   final TextStyle? style;
//   final String? Function(String?)? validate;
//   final String? format;
//   final bool? readonly;
//   const GenericDateTextFiled(
//       {super.key,
//       this.initial,
//       this.onChanged,
//       this.contentPadding,
//       this.style,
//       this.validate,
//       this.format,
//       this.readonly});

//   @override
//   State<GenericDateTextFiled> createState() => _GenericDateTextFiledState();
// }

// class _GenericDateTextFiledState extends State<GenericDateTextFiled> {
//   final TextEditingController _controller = TextEditingController();
//   DateTime? current;
//   @override
//   void initState() {
//     current = widget.initial;
//     if (current != null) {
//       _controller.text = current!.formatDate(format: widget.format);
//     }
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GenericTextField(
//       style: widget.style,
//       contentPadding: widget.contentPadding ??
//           EdgeInsets.symmetric(vertical: 8.h, horizontal: 25.w),
//       controller: _controller,
//       readonly: true,
//       floatingTitle: true,
//       labelText: 'Birthday',
//       onChanged: (value) {},
//       textInputAction: TextInputAction.next,
//       validate: widget.validate,
//       onTap: () async {
//         if (widget.readonly == true) {
//           showCustomWarningToast('Birthday can only be updated once!');
//           return;
//         }

//         await showCustomBottomSheet<DateTime?>(
//             title: const SizedBox(),
//             backgroundColor: ColorConstant.transparent,
//             body: Column(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                       color: ColorConstant.whiteBackgroundColor,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(14.95.r),
//                         topRight: Radius.circular(14.95.r),
//                       )),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text('Select birthday'),
//                       SizedBox(height: 7.h),
//                       CustomDatePicker(
//                         initial: current,
//                         minYear: DateTime.now().subtractYear(year: 70).year,
//                         maxYear: DateTime.now().subtractYear(year: 20).year,
//                         onDateChanged: (date) {
//                           current = date;
//                         },
//                         onDateSelected: (calculatedAge) {},
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 5.h),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     elevation: 0,
//                     padding: EdgeInsets.only(top: 17.96.h, bottom: 30.h),
//                     minimumSize: const Size(double.infinity, 0),
//                     visualDensity: VisualDensity.compact,
//                     shape: const RoundedRectangleBorder(),
//                   ),
//                   child: Center(
//                     child: Text(
//                       'Submit',
//                       style: StylesConstants.textDark16w600.copyWith(
//                         color: ColorConstant.bottomsheetBlueText,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             context: context);
//         if (current != null) {
//           _controller.text = current!.formatDate(format: widget.format);
//           widget.onChanged?.call(current!);
//         }
//       },
//       borderColor: ColorConstant.textFieldBorder1,
//     );
//   }
// }
