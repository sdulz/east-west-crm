import 'package:flutter/material.dart';

/// Phone: list only (details are pushed). ≥ 840dp: list + detail pane.
class ListDetailLayout extends StatelessWidget {
  const ListDetailLayout({required this.list, required this.detail, super.key});

  static const breakpoint = 840.0;

  final Widget list;
  final Widget? detail;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;

  @override
  Widget build(BuildContext context) {
    if (!isWide(context)) return list;
    return Row(
      children: [
        SizedBox(width: 360, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              detail ??
              const Center(child: Icon(Icons.touch_app_outlined, size: 40)),
        ),
      ],
    );
  }
}
