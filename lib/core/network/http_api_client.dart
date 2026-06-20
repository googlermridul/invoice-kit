import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Generic HTTP wrapper around package:http. Useful for non-Dio flows
/// (file uploads, webhooks, SSE, etc.).
class HttpApiClient {
  HttpApiClient({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 30);

  final http.Client _client;
  final Duration _timeout;

  Uri _uri(String base, String path, [Map<String, dynamic>? query]) {
    final qp = <String, String>{};
    query?.forEach((k, v) {
      if (v != null) qp[k] = v.toString();
    });
    return Uri.parse(
      '$base$path',
    ).replace(queryParameters: qp.isEmpty ? null : qp);
  }

  Future<http.Response> get(
    String base,
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) =>
      _client.get(_uri(base, path, query), headers: headers).timeout(_timeout);

  Future<http.Response> post(
    String base,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _client
      .post(
        _uri(base, path),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body == null ? null : jsonEncode(body),
      )
      .timeout(_timeout);

  Future<http.Response> put(
    String base,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _client
      .put(
        _uri(base, path),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body == null ? null : jsonEncode(body),
      )
      .timeout(_timeout);

  Future<http.Response> patch(
    String base,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _client
      .patch(
        _uri(base, path),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: body == null ? null : jsonEncode(body),
      )
      .timeout(_timeout);

  Future<http.Response> delete(
    String base,
    String path, {
    Map<String, String>? headers,
  }) => _client.delete(_uri(base, path), headers: headers).timeout(_timeout);

  void close() => _client.close();
}
