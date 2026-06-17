import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/errors/error_mapper.dart';
import 'package:flutter_boilerplate/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultErrorMapper', () {
    const mapper = DefaultErrorMapper();

    test('maps timeout Dio errors to NetworkFailure', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      );
      final mapped = mapper.map(dio);
      expect(mapped, isA<NetworkFailure>());
    });

    test('maps 401 Dio errors to UnauthorizedFailure', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: 401),
      );
      final mapped = mapper.map(dio);
      expect(mapped, isA<UnauthorizedFailure>());
    });

    test('returns UnknownFailure for arbitrary exceptions', () {
      expect(mapper.map(Exception('x')), isA<UnknownFailure>());
    });
  });
}
