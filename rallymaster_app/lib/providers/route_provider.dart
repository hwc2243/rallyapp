import 'base/base_route_provider.dart';

import 'dart:convert';

import '../models/route_item_display.dart';
import '../models/route_plan_dto.dart';

/// Application extension point for Route API operations.
///
/// This file is generated only when it does not already exist and is preserved
/// on subsequent service builds.
class RouteProvider extends BaseRouteProvider {
  RouteProvider({required super.httpClient, required super.tenantProvider});

  /// Retrieves the ordered items belonging to one route.  Route items are
  /// retained by the selected app session rather than reloaded by each screen.
  Future<List<RouteItemDisplay>> listRouteItems(int routeId) =>
      execute(() async {
        final response = await httpClient.get(
          '$resourcePath/$routeId/items',
          headers: requestHeaders,
        );
        httpClient.ensureSuccess(response);
        final values = jsonDecode(response.body) as List<dynamic>;
        return values
            .map(
              (value) =>
                  RouteItemDisplay.fromJson(value as Map<String, dynamic>),
            )
            .toList();
      });

  /// Replaces the editable plan for [routeId] in one server transaction.
  Future<RoutePlanDto> saveRoutePlan(int routeId, RoutePlanDto plan) =>
      execute(() async {
        final response = await httpClient.put(
          '$resourcePath/$routeId/items',
          headers: requestHeaders,
          body: plan.toJson(),
        );
        httpClient.ensureSuccess(response);
        return RoutePlanDto.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      });
}
