import 'competition_checkpoint.dart';

/// The server-authoritative offline configuration for one active route.
class CompetitionRoutePackage {
  const CompetitionRoutePackage({
    required this.routeId,
    required this.rallyId,
    required this.timingPlanVersion,
    required this.carZeroStartEpochMillis,
    required this.timeZone,
    required this.distanceUnit,
    required this.scoringUnit,
    required this.carStartIntervalMillis,
    required this.maximumCheckpointScore,
    required this.acquisitionRadiusMeters,
    required this.checkpoints,
  });

  factory CompetitionRoutePackage.fromJson(
    Map<String, dynamic> json,
  ) => CompetitionRoutePackage(
    routeId: (json['routeId'] as num).toInt(),
    rallyId: (json['rallyId'] as num).toInt(),
    timingPlanVersion: (json['timingPlanVersion'] as num?)?.toInt(),
    carZeroStartEpochMillis: (json['carZeroStartEpochMillis'] as num?)?.toInt(),
    timeZone: json['timeZone'] as String?,
    distanceUnit: json['distanceUnit'] as String?,
    scoringUnit: json['scoringUnit'] as String?,
    carStartIntervalMillis: (json['carStartIntervalMillis'] as num?)?.toInt(),
    maximumCheckpointScore: (json['maximumCheckpointScore'] as num?)?.toInt(),
    acquisitionRadiusMeters:
        (json['checkpointAcquisitionRadiusMeters'] as num?)?.toDouble() ??
        150.0,
    checkpoints: (json['checkpoints'] as List<dynamic>? ?? const [])
        .map(
          (value) =>
              CompetitionCheckpoint.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false),
  );

  final int routeId;
  final int rallyId;
  final int? timingPlanVersion;
  final int? carZeroStartEpochMillis;
  final String? timeZone;
  final String? distanceUnit;
  final String? scoringUnit;
  final int? carStartIntervalMillis;
  final int? maximumCheckpointScore;
  final double acquisitionRadiusMeters;
  final List<CompetitionCheckpoint> checkpoints;
}
