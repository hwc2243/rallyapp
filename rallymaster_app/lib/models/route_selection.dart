import 'route_dto.dart';
import 'route_item_display.dart';

/// A selected route together with the route items loaded for the active session.
class RouteSelection {
  const RouteSelection({required this.route, required this.routeItems});

  final RouteDto route;
  final List<RouteItemDisplay> routeItems;
}
