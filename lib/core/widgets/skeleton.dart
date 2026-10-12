import 'package:flutter/material.dart';

/// Loading placeholder that keeps layout stable.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6});
  final int rows;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    Widget bar(double w, double h) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
    return Semantics(
      label: 'Loading',
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (_, _) => Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(180, 14),
                  const SizedBox(height: 8),
                  bar(120, 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
