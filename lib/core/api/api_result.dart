/// Functional result type used by repositories.
sealed class ApiResult<T> {
  const ApiResult();

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message, int? code) onFailure,
  }) => switch (this) {
    ApiSuccess<T>(:final data) => onSuccess(data),
    ApiFailureResult<T>(:final message, :final code) => onFailure(message, code),
  };
}

class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;
}

class ApiFailureResult<T> extends ApiResult<T> {
  const ApiFailureResult(this.message, {this.code});
  final String message;
  final int? code;
}
