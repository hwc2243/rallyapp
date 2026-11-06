import 'dart:convert';

import '../models/organization_dto.dart';
import '../models/user_dto.dart';
import 'external_api_client.dart';

/// Calls the RallyMaster external identity endpoints with the current OAuth
/// bearer token. The shared client supplies access tokens; this provider never
/// stores them.
class MeProvider {
  MeProvider({required this.apiClient});

  final ExternalApiClient apiClient;

  /// Returns the authenticated RallyMaster user from `GET /api/external/me`.
  Future<UserDto> me() async {
    final response = await apiClient.get('/api/external/me');
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        'Unexpected response from /api/external/me.',
        response.statusCode,
      );
    }
    return UserDto.fromJson(body);
  }

  /// Returns the organizations belonging to the authenticated user from
  /// `GET /api/external/me/mine`.
  Future<List<OrganizationDto>> mine() async {
    final response = await apiClient.get('/api/external/me/mine');
    final body = jsonDecode(response.body);
    if (body is! List) {
      throw ApiException(
        'Unexpected response from /api/external/me/mine.',
        response.statusCode,
      );
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw ApiException(
              'Unexpected organization entry from /api/external/me/mine.',
              response.statusCode,
            );
          }
          return OrganizationDto.fromJson(item);
        })
        .toList(growable: false);
  }
}
