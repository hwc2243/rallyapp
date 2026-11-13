class RallySettings {
  const RallySettings({
    required this.distanceUnit,
    required this.scoringUnit,
    required this.carStartIntervalMillis,
    this.defaultSpeed,
    this.defaultRestartIntervalMillis,
    this.defaultPauseDurationMillis,
  });

  final String distanceUnit;
  final String scoringUnit;
  final int carStartIntervalMillis;
  final double? defaultSpeed;
  final int? defaultRestartIntervalMillis;
  final int? defaultPauseDurationMillis;

  factory RallySettings.fromJson(Map<String, dynamic> json) => RallySettings(
    distanceUnit: json['distanceUnit'] as String? ?? 'MILES',
    scoringUnit: json['scoringUnit'] as String? ?? 'SECONDS',
    carStartIntervalMillis:
        (json['carStartIntervalMillis'] as num?)?.toInt() ?? 60000,
    defaultSpeed: (json['defaultSpeed'] as num?)?.toDouble(),
    defaultRestartIntervalMillis: (json['defaultRestartIntervalMillis'] as num?)
        ?.toInt(),
    defaultPauseDurationMillis: (json['defaultPauseDurationMillis'] as num?)
        ?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'distanceUnit': distanceUnit,
    'scoringUnit': scoringUnit,
    'carStartIntervalMillis': carStartIntervalMillis,
    if (defaultSpeed != null) 'defaultSpeed': defaultSpeed,
    if (defaultRestartIntervalMillis != null)
      'defaultRestartIntervalMillis': defaultRestartIntervalMillis,
    if (defaultPauseDurationMillis != null)
      'defaultPauseDurationMillis': defaultPauseDurationMillis,
  };
}
