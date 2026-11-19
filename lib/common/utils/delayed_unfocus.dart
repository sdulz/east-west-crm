import 'package:flutter/material.dart';

void delayedUnFocus(BuildContext context) async {
  await Future.delayed(const Duration(milliseconds: 25));
  if (!context.mounted) return;
  FocusScope.of(context).unfocus();
}
