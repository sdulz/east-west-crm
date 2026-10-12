import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Every way a repository call can fail. Sealed so the UI can exhaustively
/// decide between "queue and retry later" and "final, show it now".
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network() = NetworkFailure;
  const factory Failure.timeout() = TimeoutFailure;
  const factory Failure.permissionDenied() = PermissionDeniedFailure;
  const factory Failure.validation(String message, {String? field}) =
      ValidationFailure;
  const factory Failure.conflict() = ConflictFailure;
  const factory Failure.unknown([String? message]) = UnknownFailure;
  const Failure._();

  /// Transient failures are the only ones that may be queued for retry
  /// (FR-MOB-013). Validation, permission and conflict are final.
  bool get isTransient => switch (this) {
    NetworkFailure() || TimeoutFailure() => true,
    _ => false,
  };
}

/// Typed alias used throughout repositories.
typedef FailureOr<T> = ({T? value, Failure? failure});
