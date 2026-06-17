/// Base class for all in-app exceptions that we deliberately throw.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.cause, this.statusCode});
  final int? statusCode;
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.cause});
}

class FormatException2 extends AppException {
  const FormatException2(super.message, {super.cause});
}
