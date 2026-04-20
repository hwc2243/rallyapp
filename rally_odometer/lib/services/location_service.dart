import 'package:geolocator/geolocator.dart';

enum OdometerDirection { forward, park, reverse }

class LocationUpdateResult {
  final double distance;
  final double displaySpeed;
  final bool isStationaryLock;

  LocationUpdateResult({
    required this.distance,
    required this.displaySpeed,
    required this.isStationaryLock,
  });
}

class LocationService {
  // Constants from IMPLEMENTATION.md
  static const double maxAccuracyThreshold = 15.0; // meters
  static const int backgroundGapThresholdSeconds = 5;
  static const double stationaryLockMinSpeed = 0.8; // m/s
  static const double stationaryLockUnlockSpeed = 1.2; // m/s
  static const int stationaryLockDurationSeconds = 3;
  static const double transitionSpeedThreshold = 2.5; // m/s
  static const double minMovementThreshold = 1.5; // meters

  OdometerDirection direction = OdometerDirection.forward;
  bool _isLocked = false;
  bool get isStationaryLock => _isLocked;
  set isStationaryLock(bool value) => _isLocked = value;
  DateTime? _lowSpeedStartTime;
  DateTime? _lastTimestamp;

  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

  LocationUpdateResult processLocationUpdate({
    required Position? lastPosition,
    required Position currentPosition,
    required double calibrationFactor,
  }) {
    final DateTime now = DateTime.now();
    double deltaDistance = 0.0;
    double currentSpeed = currentPosition.speed;

    // 1. The Accuracy Gate
    if (currentPosition.accuracy > maxAccuracyThreshold) {
      return LocationUpdateResult(
        distance: 0.0,
        displaySpeed: _isLocked ? 0.0 : currentSpeed,
        isStationaryLock: _isLocked,
      );
    }

    if (_lastTimestamp != null) {
      if (now.difference(_lastTimestamp!).inSeconds > backgroundGapThresholdSeconds) {
        // Discard first sample after gap (Resync)
        _lastTimestamp = now;
        return LocationUpdateResult(
          distance: 0.0,
          displaySpeed: _isLocked ? 0.0 : currentSpeed,
          isStationaryLock: _isLocked,
        );
      }
    }
    _lastTimestamp = now;

    // 2. The Stationary Lock (Hysteresis)
    if (currentSpeed < stationaryLockMinSpeed) {
      _lowSpeedStartTime ??= now;
      if (now.difference(_lowSpeedStartTime!).inSeconds >= stationaryLockDurationSeconds) {
        _isLocked = true;
      }
    } else {
      _lowSpeedStartTime = null;
    }

    if (_isLocked) {
      if (currentSpeed > stationaryLockUnlockSpeed) {
        _isLocked = false;
      } else {
        // Force speed_multiplier = 0.0 and discard distance
        return LocationUpdateResult(
          distance: 0.0,
          displaySpeed: 0.0,
          isStationaryLock: true,
        );
      }
    }

    // 3. The Speed-Sense Sieve
    if (direction == OdometerDirection.park || lastPosition == null) {
      return LocationUpdateResult(
        distance: 0.0,
        displaySpeed: currentSpeed,
        isStationaryLock: _isLocked,
      );
    }

    final double rawDistance = Geolocator.distanceBetween(
      lastPosition.latitude,
      lastPosition.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    bool shouldAccumulate = false;
    if (currentSpeed < stationaryLockMinSpeed) {
      // STATIONARY (Speed < 0.8 m/s): Strictly ignore all GPS coordinate changes.
      shouldAccumulate = false;
    } else if (currentSpeed <= transitionSpeedThreshold) {
      // TRANSITION (Speed 0.8 to 2.5 m/s): Only accumulate if delta_distance > 1.5 meters
      if (rawDistance > minMovementThreshold) {
        shouldAccumulate = true;
      }
    } else {
      // ACTIVE (Speed > 2.5 m/s): Accumulate all delta_distance
      shouldAccumulate = true;
    }

    if (shouldAccumulate) {
      // 4. The final Calculation
      double dirMult = 1.0;
      if (direction == OdometerDirection.reverse) {
        dirMult = -1.0;
      }
      
      deltaDistance = rawDistance * calibrationFactor * dirMult;
    }

    return LocationUpdateResult(
      distance: deltaDistance,
      displaySpeed: currentSpeed,
      isStationaryLock: _isLocked,
    );
  }

  Future<bool> handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }
}

