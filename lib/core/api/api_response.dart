import 'package:equatable/equatable.dart';

/// Standard server response envelope.
class ApiResponse<T> extends Equatable {
  const ApiResponse({required this.data, this.message, this.meta});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic raw) decoder) {
    return ApiResponse<T>(
      data: decoder(json['data']),
      message: json['message'] as String?,
      meta: json['meta'] is Map
          ? ApiMeta.fromJson(Map<String, dynamic>.from(json['meta'] as Map))
          : null,
    );
  }

  final T data;
  final String? message;
  final ApiMeta? meta;

  @override
  List<Object?> get props => [data, message, meta];
}

class ApiMeta extends Equatable {
  const ApiMeta({required this.page, required this.perPage, required this.total});

  factory ApiMeta.fromJson(Map<String, dynamic> json) => ApiMeta(
    page: (json['page'] as num?)?.toInt() ?? 1,
    perPage: (json['perPage'] as num?)?.toInt() ?? 20,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  final int page;
  final int perPage;
  final int total;

  @override
  List<Object?> get props => [page, perPage, total];
}
