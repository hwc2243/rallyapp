import 'checkpoint_dto.dart';
import 'route_instruction_dto.dart';

/// Complete editable plan sent to the route-plan save endpoint.
class RoutePlanDto {
  const RoutePlanDto({
    this.routeInstructions = const [],
    this.checkpoints = const [],
  });

  factory RoutePlanDto.fromJson(Map<String, dynamic> json) => RoutePlanDto(
    routeInstructions: ((json['routeInstructions'] as List?) ?? const [])
        .map(
          (item) => RouteInstructionDto.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
    checkpoints: ((json['checkpoints'] as List?) ?? const [])
        .map((item) => CheckpointDto.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  final List<RouteInstructionDto> routeInstructions;
  final List<CheckpointDto> checkpoints;

  Map<String, dynamic> toJson() => {
    'routeInstructions': routeInstructions
        .map((item) => item.toJson())
        .toList(),
    'checkpoints': checkpoints.map((item) => item.toJson()).toList(),
  };
}
