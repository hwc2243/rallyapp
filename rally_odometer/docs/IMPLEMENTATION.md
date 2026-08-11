# Implementation Plan: Rally Odometer

## Technical Stack
- **State Management:** Riverpod (20Hz telemetry & high-frequency updates).
- **Location Engine:** `geolocator` package configured for background updates and high accuracy.
- **Background Mode:** `flutter_background_service` / native OS background location permissions (`UIBackgroundModes` location on iOS, `ACCESS_BACKGROUND_LOCATION` on Android).
- **Persistence:** `shared_preferences` key-value store.

## Telemetry Data Schema
```dart
class LiveTelemetry {
  final double totalDistance;
  final double intervalDistance;
  final DateTime timestamp;
  final double speed;        // in m/s or user units
  final double bearing;      // 0.0 - 360.0 degrees
  final double latitude;
  final double longitude;
  final double gpsAccuracy;   // in meters

  LiveTelemetry({
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