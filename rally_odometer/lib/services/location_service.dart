import 'dart:collection';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

enum OdometerDirection { forward, park, reverse }

class GpsSyncResult {
  final bool acceptedFix;
  final bool hardResetAnchor;
  final Position? anchorPosition;
  final double gpsDelta;
  final double smoothedSpeed;
  final bool isStationaryLock;

  const GpsSyncResult({
    required this.acceptedFix,
    required this.hardResetAnchor,
    required this.anchorPosition,
    required this.gpsDelta,
    required this.smoothedSpeed,
    required this.isStationaryLock,
  });
}

class LocationService {
  static const double maxAccuracyThreshold = 15.0;
  static const int backgroundGapThresholdSeconds = 5;
  static const double stationaryLockMinSpeed = 0.8;
  static const double stationaryLockUnlockSpeed = 1.2;
  static const int stationaryLockDurationSeconds = 3;
  static const int speedSmoothingWindow = 3;
  static const int calibrationReadingCount = 3;
  static const double calibrationStabilityThresholdMeters = 10.0;
  static const double lowSpeedMinimum = 0.3;
  static const double lowSpeedMaximum = 1.2;
  static const int lowSpeedWindowSize = 3;
  static const double lowSpeedMovementThresholdMeters = 0.2;

  OdometerDirection direction = OdometerDirection.forward;

  final ListQueue<double> _recentSpeeds = ListQueue<double>();
  final ListQueue<Position> _calibrationPositions = ListQueue<Position>();
  final ListQueue<Position> _lowSpeedPositions = ListQueue<Position>();
  bool _isLocked = false;
  DateTime? _lowSpeedStartTime;
  DateTime? _lastAcceptedTimestamp;
  int _consecutiveLowSpeedMovementWindows = 0;

  Stream<Position> get positionStream => Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Rally Odometer is tracking',
        notificationText: 'Background GPS tracking is active.',
        enableWakeLock: true,
      ),
    ),
  );

  double get directionMultiplier {
    switch (direction) {
      case OdometerDirection.forward:
        return 1.0;
      case OdometerDirection.park:
        return 0.0;
      case OdometerDirection.reverse:
        return -1.0;
    }
  }

  /// Returns true once three accurate readings occupy a stable position
  /// cluster. This is used to discard startup GPS drift before accumulation.
  bool isPositionStable(Position position) {
    if (position.accuracy >= maxAccuracyThreshold) {
      _calibrationPositions.clear();
      return false;
    }

    _calibrationPositions.add(position);
    while (_calibrationPositions.length > calibrationReadingCount) {
      _calibrationPositions.removeFirst();
    }
    if (_calibrationPositions.length < calibrationReadingCount) {
      return false;
    }

    final first = _calibrationPositions.first;
    return _calibrationPositions.every(
      (sample) =>
          Geolocator.distanceBetween(
            first.latitude,
            first.longitude,
            sample.latitude,
            sample.longitude,
          ) <=
          calibrationStabilityThresholdMeters,
    );
  }

  GpsSyncResult processGpsUpdate({
    required Position? lastPosition,
    required Position currentPosition,
    required double calibrationFactor,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (currentPosition.accuracy > maxAccuracyThreshold) {
      _pushSpeedSample(currentPosition.speed);
      _updateStationaryLock(currentPosition.speed, currentTime);
      return GpsSyncResult(
        acceptedFix: false,
        hardResetAnchor: false,
        anchorPosition: lastPosition,
        gpsDelta: 0.0,
        smoothedSpeed: _isLocked ? 0.0 : _smoothedSpeed(),
        isStationaryLock: _isLocked,
      );
    }

    _pushSpeedSample(currentPosition.speed);
    final lowSpeedDelta = _lowSpeedDisplacement(currentPosition);
    final hasLowSpeedMovement =
        lowSpeedDelta != null &&
        lowSpeedDelta >= lowSpeedMovementThresholdMeters;
    _updateStationaryLock(
      currentPosition.speed,
      currentTime,
      hasLowSpeedMovement: hasLowSpeedMovement,
    );
    final smoothedSpeed = _isLocked ? 0.0 : _smoothedSpeed();

    final bool hasGap =
        _lastAcceptedTimestamp != null &&
        currentTime.difference(_lastAcceptedTimestamp!).inSeconds >
            backgroundGapThresholdSeconds;
    _lastAcceptedTimestamp = currentTime;

    if (hasGap || lastPosition == null) {
      return GpsSyncResult(
        acceptedFix: true,
        hardResetAnchor: hasGap,
        anchorPosition: currentPosition,
        gpsDelta: 0.0,
        smoothedSpeed: smoothedSpeed,
        isStationaryLock: _isLocked,
      );
    }

    if (directionMultiplier == 0.0 || _isLocked) {
      return GpsSyncResult(
        acceptedFix: true,
        hardResetAnchor: false,
        anchorPosition: currentPosition,
        gpsDelta: 0.0,
        smoothedSpeed: smoothedSpeed,
        isStationaryLock: _isLocked,
      );
    }

    final rawDistance = Geolocator.distanceBetween(
      lastPosition.latitude,
      lastPosition.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final distance = lowSpeedDelta ?? rawDistance;
    final calibratedDistance = distance * calibrationFactor;
    final gpsDelta = switch (direction) {
      OdometerDirection.forward => math.max(0.0, calibratedDistance),
      OdometerDirection.park => 0.0,
      OdometerDirection.reverse => -math.max(0.0, calibratedDistance),
    };

    return GpsSyncResult(
      acceptedFix: true,
      hardResetAnchor: false,
      anchorPosition: currentPosition,
      gpsDelta: gpsDelta,
      smoothedSpeed: smoothedSpeed,
      isStationaryLock: _isLocked,
    );
  }

  void _pushSpeedSample(double speed) {
    _recentSpeeds.add(speed);
    while (_recentSpeeds.length > speedSmoothingWindow) {
      _recentSpeeds.removeFirst();
    }
  }

  double _smoothedSpeed() {
    if (_recentSpeeds.isEmpty) {
      return 0.0;
    }

    final total = _recentSpeeds.fold<double>(0.0, (sum, speed) => sum + speed);
    return total / _recentSpeeds.length;
  }

  double? _lowSpeedDisplacement(Position position) {
    if (position.speed < lowSpeedMinimum || position.speed > lowSpeedMaximum) {
      _lowSpeedPositions.clear();
      _consecutiveLowSpeedMovementWindows = 0;
      return null;
    }

    _lowSpeedPositions.add(position);
    while (_lowSpeedPositions.length > lowSpeedWindowSize) {
      _lowSpeedPositions.removeFirst();
    }
    if (_lowSpeedPositions.length < lowSpeedWindowSize) {
      return null;
    }

    final first = _lowSpeedPositions.first;
    final displacement = Geolocator.distanceBetween(
      first.latitude,
      first.longitude,
      position.latitude,
      position.longitude,
    );
    // Averaging the net displacement over the window suppresses coordinate
    // jitter while retaining a smooth forward-only walking-speed increment.
    final averagedDisplacement = displacement / (_lowSpeedPositions.length - 1);
    if (averagedDisplacement >= lowSpeedMovementThresholdMeters) {
      _consecutiveLowSpeedMovementWindows++;
    } else {
      _consecutiveLowSpeedMovementWindows = 0;
    }
    return averagedDisplacement;
  }

  void _updateStationaryLock(
    double speed,
    DateTime now, {
    bool hasLowSpeedMovement = false,
  }) {
    if (_isLocked &&
        (speed > stationaryLockUnlockSpeed ||
            _consecutiveLowSpeedMovementWindows >= 2)) {
      _isLocked = false;
      _lowSpeedStartTime = null;
    }

    if (hasLowSpeedMovement && _consecutiveLowSpeedMovementWindows >= 2) {
      _lowSpeedStartTime = null;
      return;
    }

    if (speed < stationaryLockMinSpeed) {
      _lowSpeedStartTime ??= now;
      if (now.difference(_lowSpeedStartTime!).inSeconds >=
          stationaryLockDurationSeconds) {
        _isLocked = true;
      }
      return;
    }

    _lowSpeedStartTime = null;
  }

  Future<bool> handlePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
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
