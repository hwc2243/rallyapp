enum ControllerCommandOpcode {
  resetTotal,
  resetInterval,
  toggleHold,
  bumpPlus,
  bumpMinus,
  setFprState,
  overrideMileage,
  overrideIntervalMileage,
  setCalibrationFactor,
  setMetric,
  setDecimalMinutes,
  setBumpAmount,
  setBumpRequireDoubleTap,
  setRallyTimeOffset,
}

/// A command issued by a Navigator for execution by the Controller.
class ControllerCommand {
  final ControllerCommandOpcode opcode;
  final double? numericValue;
  final String? stringValue;
  final DateTime timestamp;

  const ControllerCommand({
    required this.opcode,
    this.numericValue,
    this.stringValue,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'opcode': opcode.name,
        'numericValue': numericValue,
        'stringValue': stringValue,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ControllerCommand.fromJson(Map<String, dynamic> json) {
    return ControllerCommand(
      opcode: ControllerCommandOpcode.values.firstWhere(
        (opcode) => opcode.name == json['opcode'],
      ),
      numericValue: (json['numericValue'] as num?)?.toDouble(),
      stringValue: json['stringValue'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
