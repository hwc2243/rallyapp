/// A snapshot of the latest GPS and odometer data.
///
/// Distances are retained in meters, speed in meters per second, and GPS
/// accuracy in meters so that display units can be selected by the UI.
class LiveTelemetry {
  final double totalDistance;
  final double intervalDistance;
  final DateTime timestamp;
  final double speed;
  final double? bearing;
  final double latitude;
  final double longitude;
  final double gpsAccuracy;
  final bool isDisplayHeld;

  const LiveTelemetry({
    required this.totalDistance,
    required this.intervalDistance,
    required this.timestamp,
    required this.speed,
    required this.bearing,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracy,
    required this.isDisplayHeld,
  });

  Map<String, dynamic> toJson() => {
    'totalDistance': totalDistance,
    'intervalDistance': intervalDistance,
    'timestamp': timestamp.toIso8601String(),
    'speed': speed,
    'bearing': bearing,
    'latitude': latitude,
    'longitude': longitude,
    'gpsAccuracy': gpsAccuracy,
    'isDisplayHeld': isDisplayHeld,
  };

  factory LiveTelemetry.fromJson(Map<String, dynamic> json) {
    double asDouble(String key) => (json[key] as num).toDouble();
    return LiveTelemetry(
      totalDistance: asDouble('totalDistance'),
      intervalDistance: asDouble('intervalDistance'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: asDouble('speed'),
      bearing: (json['bearing'] as num?)?.toDouble(),
      latitude: asDouble('latitude'),
      longitude: asDouble('longitude'),
      gpsAccuracy: asDouble('gpsAccuracy'),
      isDisplayHeld: json['isDisplayHeld'] as bool? ?? false,
    );
  }
}
