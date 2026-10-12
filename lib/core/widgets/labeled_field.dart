import 'package:flutter/material.dart';

/// Key/value row used on detail screens.
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
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: t.labelMedium)),
          Expanded(child: Text(value, style: t.bodyLarge)),
          ?trailing,
        ],
      ),
    );
  }
}
