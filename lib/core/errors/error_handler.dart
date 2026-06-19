import 'dart:async';

import 'package:invoice_kit/core/errors/error_mapper.dart';
import 'package:invoice_kit/core/errors/failures.dart';

/// Centralised error handler. Use inside repositories/usecases:
/// ```dart
/// await ErrorHandler.run(() => remote.login(...));
/// ```
class ErrorHandler {
  ErrorHandler(this._mapper);

  final ErrorMapper _mapper;

  Future<T> guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error, stackTrace) {
      throw _mapper.map(error, stackTrace);
    }
  }

  Failure map(Object error, [StackTrace? stackTrace]) => _mapper.map(error, stackTrace);
}

/// Functional `Result<T>` wrapper, used by repositories to avoid throwing.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    FailureResult<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    FailureResult<T>(:final failure) => failure,
  };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    FailureResult<T>(:final failure) => onFailure(failure),
  };
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
