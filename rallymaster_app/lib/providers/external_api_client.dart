import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_session.dart';

/// Shared authenticated HTTP client for RallyMaster external API providers.
///
/// When constructed with [organizationId], every request receives the selected
/// tenant's `organizationId` header. Providers that operate before an
/// organization is selected (such as `MeProvider`) simply omit it.
class ExternalApiClient {
  ExternalApiClient({
    required this.accessToken,
    this.organizationId,
    Uri? apiBaseUri,
    this.client,
  }) : _apiBaseUri = apiBaseUri ?? Uri.parse(_defaultApiBaseUrl);

  factory ExternalApiClient.forSession({
    required Future<String> Function() accessToken,
    required AppSession session,
    Uri? apiBaseUri,
    http.Client? client,
  }) => ExternalApiClient(
    accessToken: accessToken,
    organizationId: () => session.organizationId,
    apiBaseUri: apiBaseUri,
    client: client,
  );

  static const _defaultApiBaseUrl = String.fromEnvironment(
    'RALLYMASTER_API_BASE_URL',
    defaultValue: 'https://rallymaster.connors.ddns.net',
  );

  final Future<String> Function() accessToken;
  final int? Function()? organizationId;
  final Uri _apiBaseUri;
  final http.Client? client;

  Future<http.Response> get(String path) => _send('GET', path);

  Future<http.Response> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<http.Response> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<http.Response> delete(String path) => _send('DELETE', path);

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    final token = await accessToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final selectedOrganizationId = organizationId?.call();
    if (selectedOrganizationId != null) {
      headers['organizationId'] = selectedOrganizationId.toString();
    }
    if (body != null) headers['Content-Type'] = 'application/json';

    final request = http.Request(method, _apiBaseUri.resolve(path))
      ..headers.addAll(headers)
      ..body = body == null ? '' : jsonEncode(body);
    final response = client == null
        ? await http.Response.fromStream(await request.send())
        : await http.Response.fromStream(await client!.send(request));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'External API request failed.',
        response.statusCode,
        response.body,
      );
    }
    return response;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode, [this.responseBody]);

  final String message;
  final int statusCode;
  final String? responseBody;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
