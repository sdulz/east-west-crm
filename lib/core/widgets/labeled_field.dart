import 'package:flutter/material.dart';

/// Label over value, used on detail screens (usually inside a Panel).
class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.value,
    super.key,
    this.trailing,
  });
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          trailing ?? const SizedBox(width: 8),
        ],
      ),
    );
  }
}
