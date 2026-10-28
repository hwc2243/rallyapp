import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_session.dart';
import '../models/rally_dto.dart';
import 'external_api_client.dart';

/// Provider for the tenant-scoped `/api/external/rally` API.
class RallyProvider {
  RallyProvider({required this.apiClient, required this.session});

  final ExternalApiClient apiClient;
  final AppSession session;

  Future<List<RallyDto>> listRallies() => _list('/api/external/rally');

  Future<List<RallyDto>> searchRallies() => _list('/api/external/rally/search');

  Future<RallyDto?> getRally(int id) async {
    try {
      return _rallyFromResponse(await apiClient.get('/api/external/rally/$id'));
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<RallyDto> createRally(RallyDto rally) async => _rallyFromResponse(
    await apiClient.post(
      '/api/external/rally',
      body: rally.forOrganizationId(session.organizationId).toJson(),
    ),
  );

  Future<RallyDto> updateRally(RallyDto rally) async {
    final serverId = rally.serverId;
    if (serverId == null) {
      throw ArgumentError.value(
        rally,
        'rally',
        'A server id is required to update a rally.',
      );
    }
    return _rallyFromResponse(
      await apiClient.put(
        '/api/external/rally/$serverId',
        body: rally.forOrganizationId(session.organizationId).toJson(),
      ),
    );
  }

  Future<void> deleteRally(int id) =>
      apiClient.delete('/api/external/rally/$id');

  Future<List<RallyDto>> _list(String path) async {
    final response = await apiClient.get(path);
    final body = jsonDecode(response.body);
    if (body is! List) {
      throw ApiException(
        'Unexpected Rally list response.',
        response.statusCode,
      );
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw ApiException('Unexpected Rally entry.', response.statusCode);
          }
          return RallyDto.fromJson(item);
        })
        .toList(growable: false);
  }

  RallyDto _rallyFromResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw ApiException('Unexpected Rally response.', response.statusCode);
    }
    return RallyDto.fromJson(body);
  }
}
