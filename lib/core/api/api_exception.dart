import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/errors/failures.dart';

/// Custom Dio-aware failure. Contains a [DioException] reference for debugging.
class ApiException extends Failure {
  const ApiException(
    String message, {
    this.statusCode,
    this.dioException,
    super.code = 'API_EXCEPTION',
  }) : super(message: message);

  final int? statusCode;
  final DioException? dioException;
}
