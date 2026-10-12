import 'package:field_crm/core/l10n/generated/app_localizations.dart';
import 'package:field_crm/core/result/failure.dart';
import 'package:flutter/widgets.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Validation messages come from the repository and are shown verbatim.
String failureMessage(BuildContext context, Object? error) {
  final l = context.l10n;
  return switch (error) {
    NetworkFailure() => l.errorNetwork,
    TimeoutFailure() => l.errorTimeout,
    PermissionDeniedFailure() => l.permissionDenied,
    ValidationFailure(:final message) => message,
    ConflictFailure() => l.conflictBody,
    UnknownFailure(:final message) => message ?? l.errorGeneric,
    _ => l.errorGeneric,
  };
}
