import 'checkpoint_dto.dart';
import 'route_item_dto.dart';
import 'route_instruction_dto.dart';

/// A route item together with the concrete NRI or checkpoint text for display.
class RouteItemDisplay {
  const RouteItemDisplay({
    required this.item,
    this.detail,
    this.checkpoint,
    this.routeInstruction,
  });

  final RouteItemDto item;
  final String? detail;
  final CheckpointDto? checkpoint;
  final RouteInstructionDto? routeInstruction;

  /// NRI numbers belong exclusively to route instructions; checkpoints do
  /// not participate in this sequence.
  int? get instructionNumber => routeInstruction?.instructionNumber;
}
