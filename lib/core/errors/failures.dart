import 'package:equatable/equatable.dart';

/// Base Failure contract — every domain-layer failure extends this.
abstract class Failure extends Equatable {
  const Failure({this.message = 'Unexpected error', this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, code];
}

/// No internet connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection.', super.code = 'NETWORK_FAILURE'});
}

/// Server returned 5xx or any unrecoverable backend error.
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error. Please try again later.',
    super.code = 'SERVER_FAILURE',
  });
}

/// Generic API failure (4xx other than 401).
class ApiFailure extends Failure {
  const ApiFailure({required super.message, super.code = 'API_FAILURE'});
}

/// Unauthorized (401). Trigger logout/refresh.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Session expired. Please log in again.',
    super.code = 'UNAUTHORIZED',
  });
}

/// Validation errors (422 / form-level).
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fields = const {},
    super.code = 'VALIDATION_FAILURE',
  });

  final Map<String, String> fields;

  @override
  List<Object?> get props => [...super.props, fields];
}

/// Cached / local storage failure.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Local cache failure.', super.code = 'CACHE_FAILURE'});
}

/// Unknown / uncategorised failure.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred.',
    super.code = 'UNKNOWN_FAILURE',
  });
}
