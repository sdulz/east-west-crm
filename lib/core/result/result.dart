import 'package:field_crm/core/result/failure.dart';

/// A minimal sealed result type. Every repository method returns one of these
/// so that failures are values, not exceptions.
sealed class Result<T, F> {
  const Result();

  bool get isOk => this is Ok<T, F>;
  bool get isErr => this is Err<T, F>;

  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  F? get errorOrNull => switch (this) {
    Ok() => null,
    Err(:final error) => error,
  };

  Result<R, F> map<R>(R Function(T value) f) => switch (this) {
    Ok(:final value) => Ok(f(value)),
    Err(:final error) => Err(error),
  };

  Future<Result<R, F>> flatMapAsync<R>(
    Future<Result<R, F>> Function(T value) f,
  ) async => switch (this) {
    Ok(:final value) => await f(value),
    Err(:final error) => Err(error),
  };

  R fold<R>(R Function(T value) onOk, R Function(F error) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };

  /// Unwraps the value or throws the error. Only for tests and seeds.
  T getOrThrow() => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('Result is Err: $error'),
  };
}

final class Ok<T, F> extends Result<T, F> {
  const Ok(this.value);
  final T value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, F> extends Result<T, F> {
  const Err(this.error);
  final F error;

  @override
  String toString() => 'Err($error)';
}

extension ResultFutureX<T> on Future<Result<T, Failure>> {
  /// Unwraps for use inside Riverpod `build()`: the failure becomes the
  /// provider's `AsyncError.error`, which the UI pattern-matches on.
  Future<T> get orThrow => then((r) => r.fold((v) => v, (f) => throw f));
}
