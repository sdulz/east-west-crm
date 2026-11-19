

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:field_crm/common/constant/color_constant.dart';
// import 'package:field_crm/common/constant/image_constant.dart';
// import 'package:field_crm/common/constant/style_constant.dart';



// class CustomExceptionWidget extends StatelessWidget {
//   final Error? error;
//   final Future<void> Function()? onRefresh;
//   const CustomExceptionWidget({super.key, this.onRefresh, required this.error});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: RefreshIndicator(
//         onRefresh: () async {
//           await onRefresh?.call();
//         },
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text('Oops!',
//                     style: StylesConstants.primary18w700
//                         .copyWith(color: ColorConstant.primaryColor)),
//                 SizedBox(height: 20.h),
//                 const _AnimatedPandit(),
//                 if (error?.statusCode == 500) ...[
//                   Text('Something went wrong',
//                       style: StylesConstants.textDark20w600)
//                 ] else if (error?.statusCode == 404) ...[
//                   Text('Page not found!', style: StylesConstants.textDark20w600)
//                 ] else if (error?.statusCode == -1) ...[
//                   Text('Connection time out. Please Try again',
//                       style: StylesConstants.textDark20w600)
//                 ] else if (error?.statusCode == -2) ...[
//                   Text('No internet connection',
//                       style: StylesConstants.textDark20w600)
//                 ] else if (error?.statusCode == -3) ...[
//                   Text('Could not find your location',
//                       style: StylesConstants.textDark20w600)
//                 ] else ...[
//                   Text(error?.message ?? '',
//                       style: StylesConstants.textDark20w600)
//                 ],
//                 Text.rich(
//                   TextSpan(children: const [
//                     TextSpan(text: 'we encountered an error'),
//                     TextSpan(text: "\n"),
//                     TextSpan(text: "while trying to connect with our server."),
//                     TextSpan(text: "\n"),
//                     TextSpan(text: "\n"),
//                     TextSpan(text: "Please try after sometime. 😅"),
//                   ], style: StylesConstants.normalText11w400),
//                   textAlign: TextAlign.center,
//                 )
//               ]),
//         ),
//       ),
//     );
//   }
// }

