import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/errors/failures.dart';

/// Maps exceptions to domain-level [Failure]s. UI / blocs depend only on this.
abstract class ErrorMapper {
  Failure map(Object error, [StackTrace? stackTrace]);
}

class DefaultErrorMapper implements ErrorMapper {
  const DefaultErrorMapper();

  @override
  Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkFailure(message: 'Connection timed out.');
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        case DioExceptionType.badCertificate:
          return const ApiFailure(message: 'Bad SSL certificate.');
        case DioExceptionType.cancel:
          return const ApiFailure(message: 'Request cancelled.');
        case DioExceptionType.badResponse:
          return _fromBadResponse(error);
        case DioExceptionType.unknown:
          if (error.error != null) {
            return map(error.error!, error.stackTrace);
          }
          return const UnknownFailure();
      }
    }

    if (error is FormatException) {
      return const ApiFailure(message: 'Bad response format.');
    }

    if (error is TypeError) {
      debugPrint('TypeError: $error');
      return UnknownFailure(message: error.toString());
    }

    return UnknownFailure(message: error.toString());
  }

  Failure _fromBadResponse(DioException error) {
    final status = error.response?.statusCode ?? 0;
    final body = error.response?.data;

    if (status == 401) return const UnauthorizedFailure();
    if (status == 422 && body is Map && body['errors'] is Map) {
      final fields = <String, String>{};
      return ValidationFailure(message: 'Validation failed.', fields: fields);
    }
    if (status >= 500) {
      return ServerFailure(message: body?.toString() ?? '');
    }
    if (status == 403) {
      return const ApiFailure(message: 'You do not have permission.');
    }
    if (status == 404) {
      return const ApiFailure(message: 'Resource not found.');
    }
    return ApiFailure(message: body?.toString() ?? 'HTTP $status');
  }
}
