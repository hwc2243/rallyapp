import 'base/base_route_provider.dart';

import 'dart:convert';

import '../models/competitor_entry.dart';
import '../models/route_item_display.dart';
import '../models/route_plan_dto.dart';
import '../models/route_dto.dart';

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

  /// Publishes a route and records the shared password used by competitors
  /// later during registration. The password is never retained by the app.
  Future<RouteDto> publishRoute(int routeId, String? eventPassword) =>
      execute(() async {
        final response = await httpClient.put(
          '$resourcePath/$routeId/publish',
          headers: requestHeaders,
          body: {
            if (eventPassword != null && eventPassword.isNotEmpty)
              'eventPassword': eventPassword,
          },
        );
        httpClient.ensureSuccess(response);
        final published = RouteDto.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return published;
      });

  /// Lists the registered competitor teams for a route in the active organization.
  Future<List<CompetitorEntry>> listCompetitors(int routeId) =>
      execute(() async {
        final response = await httpClient.get(
          '$resourcePath/$routeId/competitors',
          headers: requestHeaders,
        );
        httpClient.ensureSuccess(response);
        final values = jsonDecode(response.body) as List<dynamic>;
        return values
            .map(
              (value) =>
                  CompetitorEntry.fromJson(value as Map<String, dynamic>),
            )
            .toList();
      });

  /// Deletes a competitor registration from a route in the active organization.
  Future<void> deleteCompetitor(int routeId, int entryId) => execute(() async {
    final response = await httpClient.delete(
      '$resourcePath/$routeId/competitors/$entryId',
      headers: requestHeaders,
    );
    httpClient.ensureSuccess(response);
  });
}
