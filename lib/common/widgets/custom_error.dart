

import 'package:flutter/material.dart';
import 'package:field_crm/common/constant/style_constant.dart';

class CustomError extends StatelessWidget {
  final String message;
  const CustomError({super.key, this.message = "something went wrong"});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: StylesConstants.fontRed14w500,));
  }
}
