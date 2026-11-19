import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class SafeBackgroundOverlay extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const SafeBackgroundOverlay({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomSystemOverlay(
      statusBarIconBrightness: () => Brightness.dark,
      statusBarColor: () => ColorConstant.backgroundColor,
      systemNavigationBarColor: () => ColorConstant.backgroundColor,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(child: child),
      ),
    );
  }
}

class CustomSystemOverlay extends ConsumerWidget {
  final Widget child;
  final bool hideScaffold;
  final Color Function()? statusBarColor;
  final Color Function()? systemNavigationBarColor;
  final Brightness Function()? statusBarIconBrightness;

  const CustomSystemOverlay({
    super.key,
    required this.child,
    this.statusBarColor,
    this.statusBarIconBrightness,
    this.systemNavigationBarColor,
    this.hideScaffold = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // rebuildWithDarkMode(ref); Implement if there is dark mode enabled
    final value =
        kIsWeb
            ? child
            : AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor:
                    statusBarColor?.call() ??
                    ColorConstant.secondaryBackgroundColor,
                //.withPrimaryDark,
                statusBarIconBrightness:
                    statusBarIconBrightness?.call() ?? Brightness.dark,
                // (isDarkMode ? Brightness.light : Brightness.dark),
                statusBarBrightness:
                    Platform.isIOS ? brightnessAsModeIOS : brightnessAsMode,
                systemNavigationBarColor:
                    systemNavigationBarColor?.call() ?? ColorConstant.white,
                //.withPrimaryDark,
                systemNavigationBarDividerColor: ColorConstant.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              child: child,
            );

    if (hideScaffold) {
      return value;
    } else {
      return Scaffold(body: value);
    }
  }

  Brightness get brightnessAsMode => Brightness.dark;

  // isDarkMode ? Brightness.light : Brightness.dark;

  Brightness get brightnessAsModeIOS => Brightness.light;
  // isDarkMode ? Brightness.dark : Brightness.light;
}
