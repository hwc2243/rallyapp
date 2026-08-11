import 'dart:collection';

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

  OdometerDirection direction = OdometerDirection.forward;

  final ListQueue<double> _recentSpeeds = ListQueue<double>();
  bool _isLocked = false;
  DateTime? _lowSpeedStartTime;
  DateTime? _lastAcceptedTimestamp;

  bool get isStationaryLock => _isLocked;
  set isStationaryLock(bool value) => _isLocked = value;

  Stream<Position> get positionStream => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
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

  GpsSyncResult processGpsUpdate({
    required Position? lastPosition,
    required Position currentPosition,
    required double calibrationFactor,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (currentPosition.accuracy > maxAccuracyThreshold) {
      return GpsSyncResult(
        acceptedFix: false,
        hardResetAnchor: false,
        anchorPosition: lastPosition,
        gpsDelta: 0.0,
        smoothedSpeed: _smoothedSpeed(),
        isStationaryLock: _isLocked,
      );
    }

    final bool hasGap =
        _lastAcceptedTimestamp != null &&
        currentTime.difference(_lastAcceptedTimestamp!).inSeconds >
            backgroundGapThresholdSeconds;
    _lastAcceptedTimestamp = currentTime;

    _pushSpeedSample(currentPosition.speed);
    _updateStationaryLock(currentPosition.speed, currentTime);

    final smoothedSpeed = _isLocked ? 0.0 : _smoothedSpeed();

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

    return GpsSyncResult(
      acceptedFix: true,
      hardResetAnchor: false,
      anchorPosition: currentPosition,
      gpsDelta: rawDistance * calibrationFactor * directionMultiplier,
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

  void _updateStationaryLock(double speed, DateTime now) {
    if (speed < stationaryLockMinSpeed) {
      _lowSpeedStartTime ??= now;
      if (now.difference(_lowSpeedStartTime!).inSeconds >=
          stationaryLockDurationSeconds) {
        _isLocked = true;
      }
      return;
    }

    _lowSpeedStartTime = null;

    if (_isLocked && speed > stationaryLockUnlockSpeed) {
      _isLocked = false;
    }
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
