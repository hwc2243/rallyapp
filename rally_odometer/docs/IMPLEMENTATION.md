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

## Startup Calibration State
- **State Variable:** `isCalibrating` (bool, default: `true`).
- **Pipeline Guard:**
  ```dart
  if (isCalibrating) {
    if (position.accuracy <= 15.0 && isPositionStable(position)) {
      isCalibrating = false; // Calibration complete
    } else {
      return; // Suppress distance calculation
    }
  }

## Calibration Factor Math
When the user submits an "Official Distance" override to calculate a new factor:
```dart
double calculateNewFactor({
  required double currentFactor,
  required double currentDisplayedDistance,
  required double officialDistance,
}) {
  if (currentDisplayedDistance <= 0.0) return currentFactor;
  return currentFactor * (officialDistance / currentDisplayedDistance);
}

## Calibration Factor Confirmation Workflow
1. **Calculation Stage:** Compute candidate factor:
   ```dart
   double proposedFactor = currentFactor * (officialDistance / currentDisplayedDistance);

## Distance Accumulation Safety & Interpolation Pipeline

### 1. The Monotonicity Guard (Distance Loss Prevention)
To prevent the odometer from losing distance during GPS noise or Soft Sync drift corrections:
- **Forward Mode (`dir_mult == 1.0`):** Enforce `AppliedDelta = max(0.0, AppliedDelta)`. 
- **Soft Sync Catch-Up Logic:** If cumulative GPS distance is *less* than cumulative Interpolated distance:
  - Do **NOT** subtract distance or snap the odometer backward.
  - Set `current_speed_multiplier = 0.0` (pause interpolation) until actual GPS movement catches up to the displayed total.
- **Reverse Mode (`dir_mult == -1.0`):** Distance reduction is explicitly permitted only in Reverse.

### 2. Stationary Noise Lock (Preventing GPS Wander)
- **Hysteresis Threshold:**
  - If `speed < 0.8 m/s` for 3s: Set `isStationaryLocked = true`.
  - While `isStationaryLocked == true`: Force `incremental_distance = 0.0`.
  - Unlock when `speed > 1.2 m/s`.

### 3. Bottom-Right Hamburger Menu
- Implement `PopupMenuButton` using `Icon(Icons.menu)` positioned in the bottom-right corner of the layout (within the control stack).

## UI Navigation & Routes

### Details Screen (`DetailsScreen`)
- **Route Architecture:** Replaces the modal `DetailsDialog` with a full page route (`DetailsScreen`) pushed onto the Navigator stack, matching `SettingsScreen`.
- **Live State Subscription:** `DetailsScreen` consumes the `LiveTelemetry` Riverpod provider to update coordinates, speed, bearing, and accuracy dynamically at runtime.
- **Color Formatting Helper:**
  ```dart
  Color getAccuracyColor(double accuracy) {
    if (accuracy < 10.0) return Colors.green;
    if (accuracy <= 15.0) return Colors.yellow;
    return Colors.red;
  }

## Numerical Entry Dialog State Handling
- **TextEditingController Handling:**
  - All factor and mileage entry dialogs maintain a `TextEditingController`.
  - **Clear Callback:** Tapping the "CLEAR" button invokes `controller.clear()`, resetting the field state to `""` and preserving active keyboard focus on the input field.

## UI Layout Rules & RenderFlex Overflow Prevention
To strictly prevent `RenderFlex` overflow exceptions across varying phone screen aspect ratios:
1. **Full-Screen Route Boilerplate Rule:**
   All secondary screens (`DetailsScreen`, `SettingsScreen`) must adopt this layout structure:
   ```dart
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(...),
       body: SafeArea(
         child: SingleChildScrollView(
           physics: const BouncingScrollPhysics(),
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 // Screen content components
               ],
             ),
           ),
         ),
       ),
     );
   }
