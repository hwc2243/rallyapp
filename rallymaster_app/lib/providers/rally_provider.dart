import 'dart:convert';

import 'base/base_rally_provider.dart';
import '../models/route_dto.dart';
import '../models/rally_settings.dart';

/// Application extension point for Rally API operations.
///
/// This file is generated only when it does not already exist and is preserved
/// on subsequent service builds.
class RallyProvider extends BaseRallyProvider {
  RallyProvider({required super.httpClient, required super.tenantProvider});

  /// Lists the routes belonging to [rallyId] through the Rally relation API.
  Future<List<RouteDto>> listRallyRoutes(int rallyId) => execute(() async {
    final response = await httpClient.get(
      '$resourcePath/$rallyId/routes',
      headers: requestHeaders,
    );
    httpClient.ensureSuccess(response);
    final values = jsonDecode(response.body) as List<dynamic>;
    return values
        .map((value) => RouteDto.fromJson(value as Map<String, dynamic>))
        .toList();
  });

  /// Whether a shared competitor password has already been configured for a
  /// rally. The endpoint deliberately returns no password or configuration.
  Future<bool> hasEventPassword(int rallyId) => execute(() async {
    final response = await httpClient.get(
      '$resourcePath/$rallyId/publish-status',
      headers: requestHeaders,
    );
    httpClient.ensureSuccess(response);
    final value = jsonDecode(response.body) as Map<String, dynamic>;
    return value['eventPasswordConfigured'] == true;
  });

  /// Saves organizer-only rally defaults. The server deliberately never returns
  /// the event password or any other secret through this endpoint.
  Future<RallySettings> getSettings(int rallyId) => execute(() async {
    final response = await httpClient.get(
      '$resourcePath/$rallyId/settings',
      headers: requestHeaders,
    );
    httpClient.ensureSuccess(response);
    return RallySettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  });

  Future<void> saveSettings(int rallyId, RallySettings settings) =>
      execute(() async {
        final response = await httpClient.put(
          '$resourcePath/$rallyId/settings',
          headers: requestHeaders,
          body: settings.toJson(),
        );
        httpClient.ensureSuccess(response);
      });
}
