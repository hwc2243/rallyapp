import 'checkpoint_dto.dart';
import 'route_item_dto.dart';

/// A route item together with the concrete NRI or checkpoint text for display.
class RouteItemDisplay {
  const RouteItemDisplay({required this.item, this.detail, this.checkpoint});

  final RouteItemDto item;
  final String? detail;
  final CheckpointDto? checkpoint;
}
