# Implementation Plan: Rally Lib (`rally_lib`)

## Technical Stack & Dependencies
- **State Management:** Riverpod (`flutter_riverpod` for 20Hz telemetry & high-frequency updates)[cite: 14].
- **Location Engine:** `geolocator` package configured for background updates and high accuracy[cite: 14].
- **Background Engine:** `flutter_background_service` with native OS permissions (`UIBackgroundModes` location on iOS, `ACCESS_BACKGROUND_LOCATION` on Android)[cite: 14].
- **Persistence:** `shared_preferences` key-value store[cite: 14].

## Telemetry Data Schema
```dart
class LiveTelemetry {
  final double totalDistance;
  final double intervalDistance;
  final DateTime timestamp;
  final double speed;        // in m/s or user units
  final double bearing;      // 0.0 - 360.0 degrees (nullable / NaN handling)
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
```[cite: 14]

## Startup Calibration State Engine
- **State Variable:** `isCalibrating` (bool, default: `true`)[cite: 14].
- **Pipeline Guard:**
  ```dart
  if (isCalibrating) {
    if (position.accuracy <= 15.0 && isPositionStable(position)) {
      isCalibrating = false; // Calibration complete
    } else {
      return; // Suppress distance calculation
    }
  }
  ```[cite: 14]

## Pure Math & Calculation Utilities
```dart
double calculateNewFactor({
  required double currentFactor,
  required double currentDisplayedDistance,
  required double officialDistance,
}) {
  if (currentDisplayedDistance <= 0.0) return currentFactor;
  return currentFactor * (officialDistance / currentDisplayedDistance);
}
```[cite: 14]

## Distance Accumulation Safety & Interpolation Pipeline

### 1. The Monotonicity Guard (Distance Loss Prevention)
To prevent the odometer from losing distance during GPS noise or Soft Sync drift corrections:
- **Forward Mode (`dir_mult == 1.0`):** Enforce `AppliedDelta = max(0.0, AppliedDelta)`[cite: 14].
- **Soft Sync Catch-Up Logic:** If cumulative GPS distance is *less* than cumulative Interpolated distance:
  - Do **NOT** subtract distance or snap the odometer backward[cite: 14].
  - Set `current_speed_multiplier = 0.0` (pause interpolation) until actual GPS movement catches up to the displayed total[cite: 14].
- **Reverse Mode (`dir_mult == -1.0`):** Distance reduction is explicitly permitted only in Reverse[cite: 14].

### 2. Stationary Noise Lock & Anchor Snapping
- **Hysteresis Threshold:**
  - If `speed < 0.8 m/s` for 3s: Set `isStationaryLocked = true`[cite: 14].
  - While `isStationaryLocked == true`: Force `incremental_distance = 0.0` and continuously reset reference anchor (`lastKnownPosition = currentPosition`) to absorb GPS drift[cite: 14].
  - Unlock when `speed > 1.2 m/s` for 2 consecutive updates[cite: 14].

## Persistence & Performance Rules
- **Non-Blocking Execution:** Do **NOT** call `SharedPreferences.setDouble()` or disk write I/O inside the 20Hz (50ms) interpolation loop[cite: 14].
- **Throttled Persistence:** Save `total_distance`, `interval_distance`, and `calibration_factor` to disk every 5 seconds or upon `AppLifecycleState.paused`.
- **Public API Exports:** Export all models, notifiers, services, and math utilities via `lib/rally_lib.dart`.