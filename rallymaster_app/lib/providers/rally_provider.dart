import 'dart:convert';

import 'base/base_rally_provider.dart';
import '../models/route_dto.dart';

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
}
