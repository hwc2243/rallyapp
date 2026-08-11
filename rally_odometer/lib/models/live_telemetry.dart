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

  const LiveTelemetry({
    required this.totalDistance,
    required this.intervalDistance,
    required this.timestamp,
    required this.speed,
    required this.bearing,
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracy,
  });
}
