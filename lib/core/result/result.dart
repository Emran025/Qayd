import 'package:qayd/core/error/failures.dart';

/// Discriminated result for operations that may fail with a [Failure].
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}

extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is FailureResult<T>;

  T? get valueOrNull {
    final self = this;
    if (self is Success<T>) return self.value;
    return null;
  }

  Failure? get failureOrNull {
    final self = this;
    if (self is FailureResult<T>) return self.failure;
    return null;
  }

  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    final self = this;
    if (self is Success<T>) return onSuccess(self.value);
    if (self is FailureResult<T>) return onFailure(self.failure);
    throw StateError('Result must be Success or FailureResult');
  }
}
