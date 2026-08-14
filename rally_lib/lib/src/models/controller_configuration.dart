/// Display and interaction preferences authored by the Controller.
class ControllerConfiguration {
  const ControllerConfiguration({
    required this.isMetric,
    required this.isDecimalMinutes,
    required this.rallyTimeOffsetSeconds,
    required this.bumpAmount,
    required this.bumpRequireDoubleTap,
  });

  final bool isMetric;
  final bool isDecimalMinutes;
  final int rallyTimeOffsetSeconds;
  final double bumpAmount;
  final bool bumpRequireDoubleTap;

  Map<String, dynamic> toJson() => {
        'isMetric': isMetric,
        'isDecimalMinutes': isDecimalMinutes,
        'rallyTimeOffsetSeconds': rallyTimeOffsetSeconds,
        'bumpAmount': bumpAmount,
        'bumpRequireDoubleTap': bumpRequireDoubleTap,
      };

  factory ControllerConfiguration.fromJson(Map<String, dynamic> json) =>
      ControllerConfiguration(
        isMetric: json['isMetric'] as bool? ?? false,
        isDecimalMinutes: json['isDecimalMinutes'] as bool? ?? false,
        rallyTimeOffsetSeconds: json['rallyTimeOffsetSeconds'] as int? ?? 0,
        bumpAmount: (json['bumpAmount'] as num?)?.toDouble() ?? 0.010,
        bumpRequireDoubleTap: json['bumpRequireDoubleTap'] as bool? ?? false,
      );
}
