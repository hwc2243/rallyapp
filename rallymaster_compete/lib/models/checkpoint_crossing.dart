class CheckpointTelemetrySample {
  const CheckpointTelemetrySample({
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.accuracy,
    required this.distanceToCheckpointMeters,
  });

  factory CheckpointTelemetrySample.fromJson(Map<String, dynamic> json) =>
      CheckpointTelemetrySample(
        capturedAt: DateTime.parse(json['capturedAt'] as String).toLocal(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        heading: (json['heading'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        distanceToCheckpointMeters: (json['distanceToCheckpointMeters'] as num)
            .toDouble(),
      );

  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final double accuracy;
  final double distanceToCheckpointMeters;

  Map<String, dynamic> toJson() => {
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'heading': heading,
    'speed': speed,
    'accuracy': accuracy,
    'distanceToCheckpointMeters': distanceToCheckpointMeters,
  };
}

class CheckpointCrossing {
  const CheckpointCrossing({
    required this.checkpointId,
    required this.occurredAt,
    required this.closestDistanceMeters,
    required this.accuracyMeters,
    required this.heading,
    required this.speed,
    required this.interceptLatitude,
    required this.interceptLongitude,
    required this.samples,
  });

  factory CheckpointCrossing.fromJson(
    Map<String, dynamic> json,
  ) => CheckpointCrossing(
    checkpointId: (json['checkpointId'] as num).toInt(),
    occurredAt: DateTime.parse(json['occurredAt'] as String).toLocal(),
    closestDistanceMeters: (json['closestDistanceMeters'] as num).toDouble(),
    accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
    heading: (json['heading'] as num).toDouble(),
    speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
    interceptLatitude: (json['interceptLatitude'] as num?)?.toDouble() ?? 0.0,
    interceptLongitude: (json['interceptLongitude'] as num?)?.toDouble() ?? 0.0,
    samples: (json['samples'] as List<dynamic>? ?? const [])
        .map(
          (sample) => CheckpointTelemetrySample.fromJson(
            sample as Map<String, dynamic>,
          ),
        )
        .toList(growable: false),
  );

  final int checkpointId;
  final DateTime occurredAt;
  final double closestDistanceMeters;
  final double accuracyMeters;
  final double heading;
  final double speed;
  final double interceptLatitude;
  final double interceptLongitude;
  final List<CheckpointTelemetrySample> samples;

  Map<String, dynamic> toJson() => {
    'checkpointId': checkpointId,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'closestDistanceMeters': closestDistanceMeters,
    'accuracyMeters': accuracyMeters,
    'heading': heading,
    'speed': speed,
    'interceptLatitude': interceptLatitude,
    'interceptLongitude': interceptLongitude,
    'samples': samples.map((sample) => sample.toJson()).toList(),
  };
}
