import 'package:flutter/material.dart';

/// Loading placeholder that keeps layout stable.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6});
  final int rows;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Loading',
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 180, color: color),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
