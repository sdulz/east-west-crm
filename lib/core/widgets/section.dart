import 'package:flutter/material.dart';

/// Section title above a list or panel.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Tonal container that groups related rows. No shadow, no border.
class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

/// Rounded tonal square holding an icon or an initial; list leading / logo.
class LeadingGlyph extends StatelessWidget {
  const LeadingGlyph({
    super.key,
    this.icon,
    this.text,
    this.color,
    this.size = 40,
  }) : assert(icon != null || text != null, 'icon or text');
  final IconData? icon;
  final String? text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: fg)
          : Text(
              text!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: fg,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}

/// Small tonal status label (Draft / Confirmed / Pending / Paid).
class StatusPill extends StatelessWidget {
  const StatusPill({required this.text, super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
