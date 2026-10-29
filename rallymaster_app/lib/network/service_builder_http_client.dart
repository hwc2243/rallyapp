import 'dart:convert';

import 'package:http/http.dart' as http;

import 'service_builder_http_exception.dart';

typedef ServiceBuilderHeadersProvider = Future<Map<String, String>> Function();

/// Shared HTTP transport used by generated entity providers.
class ServiceBuilderHttpClient {
  final String baseUrl;
  final http.Client client;
  final Map<String, String> defaultHeaders;
  final ServiceBuilderHeadersProvider? headersProvider;

  ServiceBuilderHttpClient({
    required this.baseUrl,
    http.Client? client,
    Map<String, String>? defaultHeaders,
    this.headersProvider,
  })  : client = client ?? http.Client(),
        defaultHeaders = {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...?defaultHeaders,
        };

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return client.get(
      _uri(path, queryParameters),
      headers: await _headers(headers),
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return client.post(_uri(path), headers: await _headers(headers), body: _encodeBody(body));
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return client.put(_uri(path), headers: await _headers(headers), body: _encodeBody(body));
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return client.delete(_uri(path), headers: await _headers(headers));
  }

  void ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServiceBuilderHttpException(
        response.statusCode,
        'HTTP request failed',
        responseBody: response.body,
      );
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      },
    );
  }

  Future<Map<String, String>> _headers(Map<String, String>? headers) async {
    final dynamicHeaders = headersProvider == null
        ? <String, String>{}
        : await headersProvider!();
    return {
      ...defaultHeaders,
      ...dynamicHeaders,
      ...?headers,
    };
  }

  String? _encodeBody(Object? body) => body == null
      ? null
      : body is String
          ? body
          : jsonEncode(body);
}
