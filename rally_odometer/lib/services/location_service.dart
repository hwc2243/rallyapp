import 'package:geolocator/geolocator.dart';

class LocationService {
  // Speed-Sense Filter Constants
  static const double minSpeedThreshold = 0.8; // m/s
  static const double activeSpeedThreshold = 2.5; // m/s
  static const double minMovementThreshold = 1.5; // meters
  static const double maxAccuracyThreshold = 15.0; // meters

  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0, // Receive updates for every move to apply custom filtering
        ),
      );

  /// Calculates the distance between two positions applying the Speed-Sense filter.
  /// Returns the distance in meters, adjusted by the calibration factor.
  /// If the movement is filtered out or accuracy is poor, returns 0.0.
  double calculateFilteredDistance({
    required Position? lastPosition,
    required Position currentPosition,
    required double calibrationFactor,
  }) {
    // Accuracy Guard: Regardless of speed, ignore any GPS fix with horizontal accuracy > 15m
    if (currentPosition.accuracy > maxAccuracyThreshold) {
      return 0.0;
    }

    if (lastPosition == null) {
      return 0.0;
    }

    final double rawDistance = Geolocator.distanceBetween(
      lastPosition.latitude,
      lastPosition.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final double speed = currentPosition.speed;
    bool shouldAccumulate = false;

    // Speed-Sense Noise Filtering Logic
    if (speed < minSpeedThreshold) {
      // STATIONARY (Speed < 0.8 m/s): Strictly ignore all GPS coordinate changes.
      shouldAccumulate = false;
    } else if (speed <= activeSpeedThreshold) {
      // TRANSITION (Speed 0.8 m/s to 2.5 m/s): Apply a "Minimum Movement" threshold
      if (rawDistance > minMovementThreshold) {
        shouldAccumulate = true;
      }
    } else {
      // ACTIVE (Speed > 2.5 m/s): Zero filtering.
      shouldAccumulate = true;
    }

    return shouldAccumulate ? (rawDistance * calibrationFactor) : 0.0;
  }

  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}
