import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/widgets/failure_text.dart';
import 'package:field_crm/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loading / empty / error (retry) / permission-denied, in one place.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.data,
    required this.onRetry,
    super.key,
    this.isEmpty,
    this.emptyMessage,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (value) {
      AsyncData(:final value) when isEmpty?.call(value) ?? false => _Message(
        icon: Icons.inbox_outlined,
        text: emptyMessage ?? l.emptyList,
      ),
      AsyncData(:final value) => data(value),
      AsyncError(:final error) when error is PermissionDeniedFailure =>
        _Message(icon: Icons.lock_outline, text: l.permissionDeniedView),
      AsyncError(:final error) => _Message(
        icon: Icons.cloud_off_outlined,
        text: failureMessage(context, error),
        action: FilledButton.tonal(onPressed: onRetry, child: Text(l.retry)),
      ),
      _ => loading ?? const SkeletonList(),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}
