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

  /// Builds the concrete display model from the polymorphic route-items API
  /// response. This keeps the subtype fields available for table editing.
  factory RouteItemDisplay.fromJson(Map<String, dynamic> json) {
    final item = RouteItemDto.fromJson(json);
    final checkpoint = item.itemType == 'CHECKPOINT'
        ? CheckpointDto.fromJson(json)
        : null;
    return RouteItemDisplay(
      item: item,
      detail: switch (item.itemType) {
        'NRI' => RouteInstructionDto.fromJson(json).instructionText,
        'CHECKPOINT' => checkpoint?.routeItemDetail,
        _ => null,
      },
      routeInstruction: item.itemType == 'NRI'
          ? RouteInstructionDto.fromJson(json)
          : null,
      checkpoint: checkpoint,
    );
  }

  /// NRI numbers belong exclusively to route instructions; checkpoints do
  /// not participate in this sequence.
  int? get instructionNumber => routeInstruction?.instructionNumber;
}
